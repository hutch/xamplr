module Xampl

  require 'fileutils'
  require 'set'
  require 'json'
  require 'yaml'
  require 'logger'

  require 'mongo'

  require 'xamplr/persisters/caching'

  #  require 'ruby-prof'

  class MongoPersister < AbstractCachingPersister
#  class MongoPersister < Persister

#    $lexical_indexes = Set.new(%w{ class pid time-stamp xampl-from xampl-to xampl-place }) unless defined?($lexical_indexes)
#    $numeric_indexes = Set.new(%w{ scheduled-delete-at }) unless defined?($numeric_indexes)
    $lexical_indexes = Set.new(%w{ class pid time-stamp }) unless defined?($lexical_indexes)
    $numeric_indexes = Set.new(%w{ scheduled-delete-at }) unless defined?($numeric_indexes)

    def MongoPersister.kind
      :mongo
    end

    def kind
      MongoPersister.kind
    end

    def MongoPersister.add_lexical_indexs(indexes)
      $lexical_indexes.merge(indexes)
    end

    def MongoPersister.add_numeric_indexs(indexes)
      $numeric_indexes.merge(indexes)
    end

    def connect(db_name, name)
      return if @db
      @logger = Logger.new('xampl.log')
      @m = Mongo::Connection.new(:logger => @logger)

=begin

      @logger.info "connection: #{ @m }"
      @m.database_names.each do |name|
        @logger.info "  DB: #{ name }"
#        puts "  DB: #{ name }"
      end
      @m.database_info.each do |info|
        @logger.info "  #{ info.inspect }"
#        puts "  #{ info.inspect }"
      end

=end

      #@m.drop_database(db_name) # !!!! kill the old one
      @db = @m.db(db_name)
      @coll = @db[name]


      index_info = @coll.index_information
      existing_indexes = Set.new
      index_info.each do | k, v |
        existing_indexes << v.first.first
      end
      existing_indexes.delete("_id")
#      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] existing indexes: #{ existing_indexes.inspect }"

      $lexical_indexes.each do | index_name |
        mongo_index_name = "idx.#{ index_name }"
        unless existing_indexes.include?(mongo_index_name) then
#          puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] create index: #{ mongo_index_name }"
          @coll.create_index(mongo_index_name)
        end
        existing_indexes.delete(mongo_index_name)
      end
      $numeric_indexes.each do | index_name |
        mongo_index_name = "idx.#{ index_name }"
        unless existing_indexes.include?(mongo_index_name) then
#          puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] create index: #{ mongo_index_name }"
          @coll.create_index(mongo_index_name)
        end
        existing_indexes.delete(mongo_index_name)
      end
#      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] un-explained indexes: #{ existing_indexes.inspect }"



      #@logger.info @db.inspect
      nil
    end

    def initialize(name=nil, format=nil, root=File.join(".", "repo"))
      super(root, name, format)

      @format = :xml_format

      connect('xampl', name)

      @root_dir = File.join(root, name)

      if Xampl.raw_persister_options[:write_through] then
        @files_dir = "#{ @root_dir }/files"
        FileUtils.mkdir_p(@files_dir) unless File.exist?(@files_dir)
      else
        @files_dir = nil
      end
    end

    def setup_db

#TODO -- define indexes
#      $lexical_indexes.each do | index_name |
#        r = @tc_db.setindex(index_name, TDB::ITLEXICAL | TDB::ITKEEP)
#      end
#      $numeric_indexes.each do | index_name |
#        @tc_db.setindex(index_name, TDB::ITDECIMAL | TDB::ITKEEP)
#      end
    end

    def close
      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] WHO IS CALLING ME???"
    end

=begin

    def query_implemented
      true
    end

    def query(hint=false)
      setup_db
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

=end

=begin

    def find_xampl(hint=false)
      setup_db
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
      setup_db
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
      setup_db
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
      setup_db

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

=end

    def start_sync_write
      setup_db
    end

    def done_sync_write
#      @logger.info "there are now #{ @coll.count } xampl cluster documents in the database"
#      puts "there are now #{ @coll.count } xampl cluster documents in the database"
    end


    def do_sync_write
      @time_stamp = Time.now.to_f.to_s

      @changed.each do |xampl, ignore|
        write(xampl)
      end
    rescue => e
      #puts "------------------------------------------------------------------------"
      #puts "MongoPersister Error:: #{ e }"
      #puts e.backtrace.join("\n")
      #puts "------------------------------------------------------------------------"
      raise RuntimeError, "MongoPersister Error:: #{ e }", e.backtrace
    end

=begin

    def how_indexed(xampl)
      raise XamplException.new(:no_index_so_no_persist) unless xampl.get_the_index
      place = File.join(xampl.class.name.split("::"), xampl.get_the_index)

      setup_db

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

=end

=begin

    def remove_all_mention(root, xampl)
      #TODO -- I THINK THIS IS WRONG... IS IT GOING WAY TOO DEEP??
      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] in #{ root } of #{ xampl }"
      xampl.remove_from(root)
      root.children.each do | child |
        remove_all_mention(child, xampl)
      end
    end

    def expunge(xampl)
      #NOTE -- this *must* be in a xampl transaction
      #NOTE -- the expunge operation is in two steps and is completed in write

      mentions = Xampl.find_mentions_of(xampl)
      mentions.each do | has_a_xampl |
        remove_all_mention(has_a_xampl, xampl)
      end
      xampl.changed
      self.expunged << xampl

      false
    end

=end

    def write(xampl)
      unless xampl.get_the_index then
#        raise XamplException.new(:no_index_so_no_persist)
        @logger.warn("trying to persist a #{ xampl.class.name } with no key")
        return
      end
#      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] #{ xampl }"

      expunging = self.expunged.include?(xampl)
      self.expunged.delete(xampl) if expunging

      place_dir = xampl.class.name.split("::")
      place = File.join( place_dir, xampl.get_the_index)
      mentions = Set.new
      xampl_in_xml = represent(xampl, mentions)
      unless xampl_in_xml && 0 < xampl_in_xml.size then
        @logger.warn "Cannot persist #{ xampl } because representation is unobtainable"
        return
      end

=begin

      #get rid of any supplimentary indexes associated with this xampl object
      query = TableQuery.new(@tc_db)
      query.add_condition('xampl-from', :equals, place)
      query.searchout

      query = TableQuery.new(@tc_db)
      query.add_condition('xampl-place', :equals, place)
      query.searchout

=end

      if expunging then
        puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] "
        file_place = "#{ @files_dir }/#{ place }"
        File.delete(file_place) if File.exists?(file_place)
        @coll.remove({ '_id' => place })

        uncache(xampl)
      else

        # We can do secondary descriptions in two primary ways: include in a single document containing them
        # in an attribute called 'secondary'; introducing a document for each secondary description that
        # refers to the primary document. The single doc approach has some advantages but the semantics of the
        # indexes might be different (e.g. one thing uses 'kind' as a primary and another as a secondary, then they
        # will not be indexed in the same way). The biggest advantage is that we have fewer documents, and it is
        # what the tokyo cabinet persister does.
        #
        # Will go with the single doc approach to start
        #

        single_document = {
                '_id' => place,
                'class' => xampl.class.name,
                'pid' => xampl.get_the_index,
                'time-stamp' => @time_stamp,
                'xampl' => xampl_in_xml
        }

        if Xampl.raw_persister_options[:mentions] then
          if 0 < mentions.size
            single_document['mentions'] = mentions_array = []
            mentions.each do | mention |
              mentions_array << {
                      'xampl-from' => place,
                      'mentioned_class' => xampl.class.name,
                      'pid' => xampl.get_the_index,
                      'xampl-to' => File.join(mention.class.name.split("::"), mention.get_the_index)
              }
            end
          end
        end

        if xampl.should_schedule_delete? and xampl.scheduled_for_deletion_at then
          single_document['scheduled-delete-at'] = xampl.scheduled_for_deletion_at
        end

        primary_description, secondary_descriptions = xampl.describe_yourself

        if secondary_descriptions && 0 < secondary_descriptions.size then
          single_document['idx'] = secondary_descriptions.insert(0, primary_description)
        else
          single_document['idx'] = [primary_description]
        end

#        puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] \n#{ single_document.inspect }"

#        @coll.update(single_document, upsert: true)

#        @coll.remove({ '_id' => place })
#        @coll.insert(single_document)

        @coll.save(single_document)

        begin
          if Xampl.raw_persister_options[:write_through] then
            place_dir = File.join( @files_dir, place_dir )
            FileUtils.mkdir_p(place_dir) unless File.exist?(place_dir)
            file_place = "#{ @files_dir }/#{ place }"
            File.open(file_place, "w") do |out|
              out.write xampl_in_xml
              if :sync == Xampl.raw_persister_options[:write_through] then
                out.fsync
                if $is_darwin then
                  out.fcntl(51, 0) # Attempt an F_FULLFSYNC fcntl to commit data to disk (darwin *ONLY*)
                end
              end
            end
            if single_document['idx'] then
              single_document.delete('xampl')
              File.open(file_place + ".idx", "w") do |out|
                out.write single_document.to_yaml
              end
            end
          end
        rescue => e
          puts "#{ File.basename __FILE__ }:#{ __LINE__ } [#{__method__}] write through failed #{ xampl }"
        end

        @write_count = @write_count + 1
        xampl.changes_accepted
      end

      return true
    end

    def read_representation(klass, pid)
      representation = nil

#      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] #{ klass }[#{ pid }]"
      place = File.join(klass.name.split("::"), pid)
      found = @coll.find_one({ '_id' => place })
#      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] found: #{found.class.name}/#{ found.inspect }"

      if found then
        representation = found['xampl']
      else
        #TODO -- enable/disable this functionality
        # try the filesystem if it is not in the TC repository
        filename = File.join(@root_dir, klass.name.split("::"), pid)
        representation = File.read(filename) if File.exist?(filename)
      end

#      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] #{ klass }[#{ pid }] found: #{ representation.class.name }"
      return representation
    end
  end

  Xampl.register_persister_kind(MongoPersister)
end

