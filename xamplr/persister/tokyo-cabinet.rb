module Xampl

  require 'fileutils'
  require 'tokyocabinet'
  require 'persister/caching'
  require 'set'

  class TokyoCabinetPersister < AbstractCachingPersister
    include TokyoCabinet

    def note_errors(msg="TokyoCabinet Error:: %s\n")
      result = yield

      rmsg = nil
      unless result then
        rmsg = sprintf(msg, @tc_db.errmsg(@tc_db.ecode))
        STDERR.printf(rmsg)
        caller(0).each do |trace|
          STDERR.puts(trace)
        end
      end
      return rmsg
    end

    $lexical_indexes = Set.new(%w{ class pid time-stamp }) unless $lexical_indexes
    $numeric_indexes = Set.new unless $numeric_indexes

    def TokyoCabinetPersister.add_lexical_indexs(indexes)
      $lexical_indexes.merge(indexes)
    end

    def TokyoCabinetPersister.add_numeric_indexs(indexes)
      $numeric_indexes.merge(indexes)
    end

    def initialize(name=nil, format=nil, root=File.join(".", "repo"))
      super(root, name, format)

      FileUtils.mkdir_p(@root_dir) unless File.exist?(@root_dir)
      @filename = "#{@root_dir}/repo.tct"

      @tc_db = TDB.new
      note_errors("TC:: tuning error: %s\n") do
        @tc_db.tune(-1, -1, -1, TDB::TDEFLATE)
      end

      note_errors("TC:: open error: %s\n") do
        @tc_db.open(@filename, TDB::OWRITER | TDB::OCREAT | TDB::OLCKNB ) #TDB::OTSYNC slows it down by almost 50 times
      end

      # Don't care if there are errors (in fact, if the index exists a failure is the expected thing)
      $lexical_indexes.each do | index_name |
        @tc_db.setindex(index_name, TDB::ITLEXICAL | TDB::ITKEEP)
      end
      $numeric_indexes.each do | index_name |
        @tc_db.setindex(index_name, TDB::ITDECIMAL | TDB::ITKEEP)
      end

      #      note_errors("TC:: optimisation error: %s\n") do
      #        @tc_db.optimize(-1, -1, -1, TDB::TDEFLATE)
      #      end
#      note_errors("TC:: close error: %s\n") do
#        @tc_db.close
#      end
    end

    def TokyoCabinetPersister.kind
      :tokyo_cabinet
    end

    def kind
      TokyoCabinetPersister.kind
    end

    def query
      query = TableQuery.new(@tc_db)

      yield query

      result_keys = query.search
      results = result_keys.collect { | key | @tc_db[ key ] }

      class_cache = {}
      results.each do | result |
        next unless result

        class_name = result['class']
        result_class = class_cache[class_name]
        unless result_class then
          class_name.split("::").each do | chunk |
            if result_class then
              result_class = result_class.const_get( chunk )
            else
              result_class = Kernel.const_get( chunk )
            end
          end

          class_cache[class_name] = result_class
        end

        result['xampl'] = self.lookup(result_class, result['pid'])
      end

      results
    end

    def find_xampl
      query = TableQuery.new(@tc_db)

      yield query

      class_cache = {}

      result_keys = query.search

      results = result_keys.collect do | key |
        result = @tc_db[ key ]
        next unless result

        class_name = result['class']
        result_class = class_cache[class_name]
        unless result_class then
          class_name.split("::").each do | chunk |
            if result_class then
              result_class = result_class.const_get( chunk )
            else
              result_class = Kernel.const_get( chunk )
            end
          end

          class_cache[class_name] = result_class
        end

        self.lookup(result_class, result['pid'])
      end

      results
    end

    def find_pids
      query = TableQuery.new(@tc_db)

      yield query

      result_keys = query.search

      result_keys
    end

    def find_meta
      query = TableQuery.new(@tc_db)

      yield query

      result_keys = query.search
      results = result_keys.collect { | key | @tc_db[ key ] }

      results
    end

    def do_sync_write
      @time_stamp = Time.now.to_f.to_s

#      puts "DO SYNC WRITE: #{ @changed.size } to be written (#{ @filename })"
#      note_errors("TC:: open error: %s\n") do
#        @tc_db.open(@filename, TDB::OWRITER | TDB::OCREAT | TDB::OLCKNB ) #TDB::OTSYNC slows it down by almost 50 times
#      end

      begin
        note_errors("TC:: tranbegin error: %s\n") do
          @tc_db.tranbegin
        end

        @changed.each do |xampl, ignore|
          write(xampl)
        end
      rescue => e
        msg = "no TC.abort attempted"
        msg = note_errors("TC:: trancommit error: %s\n") do
          @tc_db.tranabort
        end
        raise "TokyoCabinetPersister Error:: #{ msg }/#{ e }"
      else
        note_errors("TC:: trancommit error: %s\n") do
          @tc_db.trancommit
        end
      ensure
#        note_errors("TC:: close error: %s\n") do
#          @tc_db.close()
#        end
      end
#      puts "               num records: #{ @tc_db.rnum() }"
    end

    def write(xampl)
      raise XamplException.new(:no_index_so_no_persist) unless xampl.get_the_index

      place = File.join(xampl.class.name.split("::"), xampl.get_the_index)
      data = represent(xampl)

      xampl_hash = {
              'class' => xampl.class.name,
              'pid' => xampl.get_the_index,
              'time-stamp' => @time_stamp,
              'xampl' => data
      }

      hash = xampl.describe_yourself
      if hash then
        xampl_hash = hash.merge(xampl_hash)
      end

      note_errors("TC:: write error: %s\n") do
        @tc_db.put(place, xampl_hash)
      end

      @write_count = @write_count + 1
      xampl.changes_accepted
      return true
    end

    def read_representation(klass, pid)
      place = File.join(klass.name.split("::"), pid)
      representation = nil

      meta = @tc_db[place]
      representation = meta['xampl'] if meta

      # puts "read: #{ place }, size: #{ representation.size }"
      # puts representation[0..100]

      return representation
    end
  end

  #
  # Derrived from rufus-tyrant, but simplified significantly, and using the
  # TokyoCabinet named constants rather than numbers
  #

  class TableQuery
    include TokyoCabinet

    OPERATORS = {
            # strings...

            :streq => TDBQRY::QCSTREQ, # string equality
            :eq => TDBQRY::QCSTREQ,
            :eql => TDBQRY::QCSTREQ,
            :equals => TDBQRY::QCSTREQ,

            :strinc => TDBQRY::QCSTRINC, # string include
            :inc => TDBQRY::QCSTRINC, # string include
            :includes => TDBQRY::QCSTRINC, # string include

            :strbw => TDBQRY::QCSTRBW, # string begins with
            :bw => TDBQRY::QCSTRBW,
            :starts_with => TDBQRY::QCSTRBW,
            :strew => TDBQRY::QCSTREW, # string ends with
            :ew => TDBQRY::QCSTREW,
            :ends_with => TDBQRY::QCSTREW,

            :strand => TDBQRY::QCSTRAND, # string which include all the tokens in the given exp
            :and => TDBQRY::QCSTRAND,

            :stror => TDBQRY::QCSTROR, # string which include at least one of the tokens
            :or => TDBQRY::QCSTROR,

            :stroreq => TDBQRY::QCSTROREQ, # string which is equal to at least one token

            :strorrx => TDBQRY::QCSTRRX, # string which matches the given regex
            :regex => TDBQRY::QCSTRRX,
            :matches => TDBQRY::QCSTRRX,

            # numbers...

            :numeq => TDBQRY::QCNUMEQ, # equal
            :numequals => TDBQRY::QCNUMEQ,
            :numgt => TDBQRY::QCNUMGT, # greater than
            :gt => TDBQRY::QCNUMGT,
            :numge => TDBQRY::QCNUMGE, # greater or equal
            :ge => TDBQRY::QCNUMGE,
            :gte => TDBQRY::QCNUMGE,
            :numlt => TDBQRY::QCNUMLT, # greater or equal
            :lt => TDBQRY::QCNUMLT,
            :numle => TDBQRY::QCNUMLE, # greater or equal
            :le => TDBQRY::QCNUMLE,
            :lte => TDBQRY::QCNUMLE,
            :numbt => TDBQRY::QCNUMBT, # a number between two tokens in the given exp
            :bt => TDBQRY::QCNUMBT,
            :between => TDBQRY::QCNUMBT,

            :numoreq => TDBQRY::QCNUMOREQ # number which is equal to at least one token
    }

    TDBQCNEGATE = TDBQRY::QCNEGATE
    TDBQCNOIDX = TDBQRY::QCNOIDX

    DIRECTIONS = {
            :strasc => TDBQRY::QOSTRASC,
            :strdesc => TDBQRY::QOSTRDESC,
            :asc => TDBQRY::QOSTRASC,
            :desc => TDBQRY::QOSTRDESC,
            :numasc => TDBQRY::QONUMASC,
            :numdesc => TDBQRY::QONUMDESC
    }

    #
    # Creates a query for a given Rufus::Tokyo::Table
    #
    # Queries are usually created via the #query (#prepare_query #do_query)
    # of the Table instance.
    #
    # Methods of interest here are :
    #
    #   * #add (or #add_condition)
    #   * #order_by
    #   * #limit
    #
    # also
    #
    #   * #pk_only
    #   * #no_pk
    #

    def initialize (table)
      @query = TDBQRY::new(table)
      @opts = {}
    end

    #
    # Performs the search
    #

    def search
      @query.search
    end

    # limits the search

    def setlimit(max=nil, skip=nil)
      @query.setlimit(max, skip)
    end

    #
    # Adds a condition
    #
    #   table.query { |q|
    #     q.add 'name', :equals, 'Oppenheimer'
    #     q.add 'age', :numgt, 35
    #   }
    #
    # Understood 'operators' :
    #
    #   :streq # string equality
    #   :eq
    #   :eql
    #   :equals
    #
    #   :strinc # string include
    #   :inc # string include
    #   :includes # string include
    #
    #   :strbw # string begins with
    #   :bw
    #   :starts_with
    #   :strew # string ends with
    #   :ew
    #   :ends_with
    #
    #   :strand # string which include all the tokens in the given exp
    #   :and
    #
    #   :stror # string which include at least one of the tokens
    #   :or
    #
    #   :stroreq # string which is equal to at least one token
    #
    #   :strorrx # string which matches the given regex
    #   :regex
    #   :matches
    #
    #   # numbers...
    #
    #   :numeq # equal
    #   :numequals
    #   :numgt # greater than
    #   :gt
    #   :numge # greater or equal
    #   :ge
    #   :gte
    #   :numlt # greater or equal
    #   :lt
    #   :numle # greater or equal
    #   :le
    #   :lte
    #   :numbt # a number between two tokens in the given exp
    #   :bt
    #   :between
    #
    #   :numoreq # number which is equal to at least one token
    #

    def add (colname, operator, val, affirmative=true, no_index=true)
      op = operator.is_a?(Fixnum) ? operator : OPERATORS[operator]
      op = op | TDBQRY::QCNEGATE unless affirmative
      op = op | TDBQRY::QCNOIDX if no_index

      @query.addcond(colname, op, val)
    end

    alias :add_condition :add

    #
    # Sets the max number of records to return for this query.
    #
    # (If you're using TC >= 1.4.10 the optional 'offset' (skip) parameter
    # is accepted)
    #

    def limit (i, offset=-1)
      @query.setlimit(i, offset)
    end

    #
    # Sets the sort order for the result of the query
    #
    # The 'direction' may be :
    #
    #   :strasc # string ascending
    #   :strdesc
    #   :asc # string ascending
    #   :desc
    #   :numasc # number ascending
    #   :numdesc
    #

    def order_by (colname, direction=:strasc)
      @query.setorder(colname, DIRECTIONS[direction])
    end
  end

  Xampl.register_persister_kind(TokyoCabinetPersister)
end

