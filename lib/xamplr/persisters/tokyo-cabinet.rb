module Xampl

  require 'fileutils'
  require 'tokyocabinet'
  require 'xamplr/persisters/caching'
  require 'set'

  #  require 'ruby-prof'

  class TokyoCabinetPersister < AbstractCachingPersister
    include TokyoCabinet

    def note_errors(msg="TokyoCabinet Error:: %s\n")
      result = yield

      rmsg = nil
      unless result then
        rmsg = sprintf(msg, @tc_db.errmsg(@tc_db.ecode))
        STDERR.printf(rmsg)
        STDERR.puts "---------"
        caller(0).each do |trace|
          STDERR.puts(trace)
        end
        STDERR.puts "---------"
      end
      return rmsg
    end

    $lexical_indexes = Set.new(%w{ class pid time-stamp xampl-from xampl-to xampl-place }) unless defined?($lexical_indexes)

    $numeric_indexes = Set.new(%w{ scheduled-delete-at }) unless defined?($numeric_indexes)

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

      open_tc_db()

      #      note_errors("TC[[#{ @filename }]]:: optimisation error: %s\n") do
      #        @tc_db.optimize(-1, -1, -1, TDB::TDEFLATE)
      #      end
      #      note_errors("TC[[#{ @filename }]]:: close error: %s\n") do
      #        @tc_db.close
      #      end
    end

    def open_tc_db
      return if @tc_db
#      puts "#{File.basename(__FILE__)}:#{__LINE__} open tc db: #{ @filename }"
      #puts "#{File.basename(__FILE__)}:#{__LINE__} callers..."
      #caller(0).each { | trace | puts "   #{trace}"}
      @tc_db = TDB.new
      note_errors("TC[[#{ @filename }]]:: tuning error: %s\n") do
        @tc_db.tune(-1, -1, -1, TDB::TDEFLATE)
      end

      note_errors("TC[[#{ @filename }]]:: open [#{ @filename }] error: %s\n") do
        @tc_db.open(@filename, TDB::OWRITER | TDB::OCREAT | TDB::OLCKNB | TDB::OTSYNC ) #TDB::OTSYNC slows it down by almost 50 times
      end

      # Don't care if there are errors (in fact, if the index exists a failure is the expected thing)

      $lexical_indexes.each do | index_name |
        r = @tc_db.setindex(index_name, TDB::ITLEXICAL | TDB::ITKEEP)
      end
      $numeric_indexes.each do | index_name |
        @tc_db.setindex(index_name, TDB::ITDECIMAL | TDB::ITKEEP)
      end

    end

    def optimise(opts)
      return unless @tc_db

      if opts[:indexes_only] then
        # Don't care if there are errors (in fact, if the index exists a failure is the expected thing)
        $lexical_indexes.each do | index_name |
          @tc_db.setindex(index_name, 9998)
        end
        $numeric_indexes.each do | index_name |
          @tc_db.setindex(index_name, 9998)
        end
      else
        note_errors("TC[[#{ @filename }]]:: optimisation error: %s\n") do
          @tc_db.optimize(-1, -1, -1, 0xff)
        end
      end
    end

    def close
      if @tc_db then
        self.sync

        note_errors("TC[[#{ @filename }]]:: close error: %s\n") do
          @tc_db.close
        end
        @tc_db = nil
#        puts "#{File.basename(__FILE__)}:#{__LINE__} close tc db: #{ @filename }"
      end
    end

    def TokyoCabinetPersister.kind
      :tokyo_cabinet
    end

    def kind
      TokyoCabinetPersister.kind
    end

    def query_implemented
      true
    end

    def query(hint=false)
      open_tc_db
      query = TableQuery.new(@tc_db)

      yield query

      result_keys = nil
      the_hint = nil
      if hint then
        result_keys, the_hint = query.search(true)
      else
        result_keys = query.search
      end
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

      if hint then
        return results.uniq, the_hint
      else
        return results.uniq
      end
    end

    def find_xampl(hint=false)
      open_tc_db
      query = TableQuery.new(@tc_db)

      yield query

      class_cache = {}

      result_keys = nil
      the_hint = nil
      if hint then
        result_keys, the_hint = query.search(true)
      else
        result_keys = query.search
      end

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

      if hint then
        return results.uniq, the_hint
      else
        return results.uniq
      end
    end

    def find_pids(hint=false)
      open_tc_db
      query = TableQuery.new(@tc_db)

      yield query

      result_keys = nil
      the_hint = nil
      if hint then
        result_keys, the_hint = query.search(true)
      else
        result_keys = query.search
      end

      results = result_keys.collect do |key|
        meta = @tc_db[ key ]
        meta['xampl-place'] || meta['place']
      end

      if hint then
        return results.uniq, the_hint
      else
        return results.uniq
      end
    end

    def find_meta(hint=false)
      open_tc_db
      query = TableQuery.new(@tc_db)

      yield query

      result_keys = nil
      the_hint = nil
      if hint then
        result_keys, the_hint = query.search(true)
      else
        result_keys = query.search
      end

      results = result_keys.collect { | key | @tc_db[ key ] }

      if hint then
        return results, the_hint
      else
        return results
      end
    end

    def find_mentions_of(xampl)
      open_tc_db

      place = File.join(xampl.class.name.split("::"), xampl.get_the_index)

      query = TableQuery.new(@tc_db)
      query.add_condition('xampl-to', :equals, place)
      result_keys = query.search

      class_cache = {}
      results = result_keys.collect do | key |
        result = @tc_db[ key ]
        next unless result

        mentioner = result['xampl-from']
        class_name = result['mentioned_class']
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
      return results.uniq
    end

    def do_sync_write
#      RubyProf.start
      #
      #      do_sync_write_work
      #
      #      result = RubyProf.stop
      #      printer = RubyProf::FlatPrinter.new(result)
      #      printer.print(STDOUT, 0)
      #      puts "#{File.basename(__FILE__)}:#{__LINE__} stop this profiler"
      #    end
      #
      #    def do_sync_write_work
      open_tc_db
      @time_stamp = Time.now.to_f.to_s

#            puts "DO SYNC WRITE: #{ @changed.size } to be written (#{ @filename })"
      #      note_errors("TC:: open error: %s\n") do
      #        @tc_db.open(@filename, TDB::OWRITER | TDB::OCREAT | TDB::OLCKNB ) #TDB::OTSYNC slows it down by almost 50 times
      #      end

      begin
        note_errors("TC[[#{ @filename }]]:: tranbegin error: %s\n") do
          @tc_db.tranbegin
        end

        @changed.each do |xampl, ignore|
          write(xampl)
        end
      rescue => e
        msg = "no TC.abort attempted"
        msg = note_errors("TC[[#{ @filename }]]:: trancommit error: %s\n") do
          @tc_db.tranabort
        end
        puts "------------------------------------------------------------------------"
        puts "TokyoCabinetPersister Error:: #{ msg }/#{ e }"
        puts e.backtrace.join("\n")
        puts "------------------------------------------------------------------------"
        raise "TokyoCabinetPersister Error:: #{ msg }/#{ e }"
      else
        note_errors("TC[[#{ @filename }]]:: trancommit error: %s\n") do
          @tc_db.trancommit
        end
      ensure
#                note_errors("TC[[#{ @filename }]]:: close error: %s\n") do
#                  @tc_db.close()
#                end
      end
#      puts "               num records: #{ @tc_db.rnum() }"
      #      puts "#{ __FILE__ }:#{ __LINE__ } keys..."
      #      @tc_db.keys.each do | key |
      #        meta = @tc_db[key]
      #        meta['xampl'] = (meta['xampl'] || "no rep")[0..25]
      #        puts "         key: [#{ key }] -- #{ meta.inspect }"
      #      end
    end

    def how_indexed(xampl)
      raise XamplException.new(:no_index_so_no_persist) unless xampl.get_the_index
      place = File.join(xampl.class.name.split("::"), xampl.get_the_index)

      open_tc_db

      result_keys = Set.new

      query = TableQuery.new(@tc_db)
      query.add_condition('xampl-place', :equals, place)
      search_results = query.search
      result_keys.merge( search_results)

      primary = @tc_db[ place ]
      if primary then
        primary.delete('xampl')
      end

      results = primary ? [ primary ] : []
      result_keys.each do | key |
        result = @tc_db[ key ]
        next unless result

        result.delete('xampl')

        results << result
      end

      results
    end

    def write(xampl)
      raise XamplException.new(:no_index_so_no_persist) unless xampl.get_the_index

      place = File.join(xampl.class.name.split("::"), xampl.get_the_index)
      mentions = Set.new
      data = represent(xampl, mentions)

      #get rid of any supplimentary indexes associated with this xampl object
      query = TableQuery.new(@tc_db)
      query.add_condition('xampl-from', :equals, place)
      note_errors("TC[[#{ @filename }]]:: failed to remove from mentions, error: %s\n") do
        query.searchout
      end

      query = TableQuery.new(@tc_db)
      query.add_condition('xampl-place', :equals, place)
      note_errors("TC[[#{ @filename }]]:: failed to remove from mentions, error: %s\n") do
        query.searchout
      end

      mentions.each do | mention |
        mention_place = File.join(mention.class.name.split("::"), mention.get_the_index)
        #TODO -- will repeadedly changing a persisted xampl object fragment the TC db?

        pk = @tc_db.genuid
        mention_hash = {
                'xampl-from' => place,
                'mentioned_class' => xampl.class.name,
                'pid' => xampl.get_the_index,
                'xampl-to' => mention_place
        }

        note_errors("TC[[#{ @filename }]]:: write error: %s\n") do
          @tc_db.put(pk, mention_hash)
        end
      end

      xampl_hash = {
              'class' => xampl.class.name,
              'pid' => xampl.get_the_index,
              'time-stamp' => @time_stamp,
              'xampl' => data
      }

      primary_description, secondary_descriptions = xampl.describe_yourself
      if primary_description then
        xampl_hash = primary_description.merge(xampl_hash)
      end

      note_errors("TC[[#{ @filename }]]:: write error: %s\n") do
        @tc_db.put(place, xampl_hash)
      end

      #TODO -- smarter regarding when to delete (e.g. mentions)
      if xampl.should_schedule_delete? and xampl.scheduled_for_deletion_at then
        secondary_descriptions = [] unless secondary_descriptions
        secondary_descriptions << { 'scheduled-delete-at' => xampl.scheduled_for_deletion_at }
      elsif xampl.scheduled_for_deletion_at then
        puts "#{ __FILE__ }:#{ __LINE__ } HOW TO DO THIS without violating xampl's change rules????? "
        #xampl.scheduled_for_deletion_at = nil
      end

      if secondary_descriptions then
        xampl_hash = {
                'class' => xampl.class.name,
                'pid' => xampl.get_the_index,
                'xampl-place' => place
        }

        secondary_descriptions.each do | secondary_description |
          description = secondary_description.merge(xampl_hash)

          note_errors("TC[[#{ @filename }]]:: write error: %s\n") do
            pk = @tc_db.genuid
            @tc_db.put(pk, description)
          end
        end
      end

      @write_count = @write_count + 1
      xampl.changes_accepted
      return true
    end

    $TC_COUNT = 0
    $FS_COUNT = 0
    $NF_COUNT = 0

    def read_representation(klass, pid)
      #TODO -- is this being called too often, e.g. by new_xxx???
      #      puts "#{File.basename(__FILE__)}:#{__LINE__} READ #{ klass }/#{ pid }"
      #      caller(0).each { | trace | puts "  #{trace}"}

      open_tc_db
      place = File.join(klass.name.split("::"), pid)
      representation = nil

      meta = @tc_db[place]
      representation = meta['xampl'] if meta

      #      puts "#{File.basename(__FILE__)}:#{__LINE__} TC: #{ klass }/#{ pid }" if representation
      $TC_COUNT += 1 if representation

      # puts "read: #{ place }, size: #{ representation.size }"
      # puts representation[0..100]

      unless representation then
        # try the filesystem if it is not in the TC repository
        place = File.join(@root_dir, klass.name.split("::"), pid)
        representation = File.read(place) if File.exist?(place)
        $FS_COUNT += 1 if representation
#        puts "#{File.basename(__FILE__)}:#{__LINE__} FS: #{ klass }/#{ pid } (FS: #{ $FS_COUNT}, TC: #{ $TC_COUNT }, NF: #{ $NF_COUNT }" if representation
      end
#      puts "#{File.basename(__FILE__)}:#{__LINE__} ??: #{ klass }/#{ pid }" unless representation
      $NF_COUNT += 1

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
      @text_form = []
      @opts = {}
    end

    #
    # Performs the search
    #

    def search(hint=false)
      r = @query.search
      if hint then
        return r, @query.hint
      else
        return r
      end
    end

    #
    #  Performs the search and removes whatever's found
    #

    def searchout
      r = @query.searchout
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

    def add (colname, operator, val, affirmative=true, no_index=false)
      op = operator.is_a?(Fixnum) ? operator : OPERATORS[operator]
      op = op | TDBQRY::QCNEGATE unless affirmative
      op = op | TDBQRY::QCNOIDX if no_index

      @text_form << "operator: #{ operator }#{ affirmative ? '' : ' NEGATED'}#{ no_index ? ' NO INDEX' : ''} -- col: '#{ colname }', val: '#{ val }'"

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

    def inspect
      "TableQuery:\n#{ @text_form.join("\n") }"
    end

    def to_s
      inspect
    end
  end

  Xampl.register_persister_kind(TokyoCabinetPersister)
end

