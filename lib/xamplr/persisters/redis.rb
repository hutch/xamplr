module Xampl

  class RedisPersister < Persister

    attr_reader :repo_name,
                :instance_options,
                :client, # currently it's an instance of ::Redis from the redis-rb library
                :suggested_repo_properties,
                :repo_properties

    @@default_redis_options = {
            :repo_properties => {
                    # DB Properties, maybe only set when the DB is created for the first time.
                    :mentions => true,
                    },

            # Connect Properties
            :thread_safe => true, # redis connections will be thread safe
            :redis_server => "redis://127.0.0.1:6379/0", #This is the format expected by redis-rb, just use it
            :clobbering_allowed => false,
            :allow_connections => true,
            :connect_to_known => true, # will connect to repos already in the redis db
            :connect_to_unknown => true, # will connect to repose not in the redis db
            :testing => false
    }

    REPOSITORIES_KEY = "XAMPL::REPOSITORIES"

    def initialize(name=nil, format=nil, options={})
      super(name, format)

      @repo_name = name
#      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] @@default_redis_options: #{ @@default_redis_options.inspect }"
#      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] Xampl.raw_persister_options: #{ Xampl.raw_persister_options.inspect }"
#      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] options: #{ options.inspect }"

      @instance_options = {}
      @instance_options = @instance_options.merge(@@default_redis_options)
      @instance_options = @instance_options.merge(Xampl.raw_persister_options)
      @instance_options = @instance_options.merge(options) if options

      @suggested_repo_properties = @instance_options.delete(:repo_properties)

      clear_cache
      ensure_connected
    end

    def RedisPersister.kind
      :redis
    end

    def kind
      RedisPersister.kind
    end

    def ensure_connected
      return if @client
      return unless instance_options[:allow_connections]

      server = @instance_options[:redis_server]
      thread_safe = @instance_options[:thread_safe]
      @client = Redis.connect(:url => server, :thread_safe => thread_safe)

      # This check is necessary to make sure that the connection is made, otherwise the exception will be sometime in the future
      # the redis exceptions are good enough, so don't bother trapping right here
      @client.ping

      # check to see if the repository with this name is known (in redis) already
      load_repo_properties

      if @repo_properties && !@instance_options[:connect_to_known] then
        ensure_disconnected
        raise IncompatiblePersisterConfiguration.new('redis', "prevent connections to existing repos named: '#{ repo_name }' in #{ server }")
      end
      if @repo_properties.nil? && !@instance_options[:connect_to_unknown] then
        ensure_disconnected
        raise IncompatiblePersisterConfiguration.new('redis', "prevent connections to unknown repos named: '#{ repo_name }' in #{ server }")
      end

      return if @repo_properties

      # if it is unknown, then set it up

      @repo_properties = {}
      suggested_repo_properties.each do |k, v|
        @repo_properties[k] = v
      end
      @repo_properties['name'] = repo_name
      @repo_properties['created_at'] = DateTime.now.to_s

      @client.multi do
        @client.mapped_hmset(repo_properties_key, @repo_properties)
        @client.sadd(REPOSITORIES_KEY, repo_name)
      end

      load_repo_properties
    end

    def ensure_disconnected
      return unless client
      return unless instance_options[:allow_connections]

      @client.quit
    ensure
      @repo_properties = nil
      @client = nil
    end

    def clobber
      # TODO -- this is a BAD idea if there are any other connections to this repo (i.e. in different processes)

      unless @instance_options[:clobbering_allowed] then
        raise IncompatiblePersisterConfiguration.new('redis', "clobbering is not enabled for this connection to repo: '#{ repo_name }' in #{ @instance_options[:redis_server] }")
      end

      #TODO -- getting the keys outside the multi might allow some new key to sneak in there
      keys = @client.keys("#{ common_key_prefix }*")
      @client.multi do
        @client.del(repo_properties_key)
        @client.srem(REPOSITORIES_KEY, repo_name)

        keys.each do |key|
          @client.del(key)
        end
      end

      ensure_disconnected
    end

    def repo_properties_key
      key = "XAMPL::PROPERTIES::#{ @repo_name }"
      return key
    end

    def load_repo_properties
      key = repo_properties_key()
      @repo_properties = @client.hgetall(key)
      @repo_properties = nil if @repo_properties.empty?
    end

    def clear_cache
      @cache_hits = 0
      @cache = {}
      @new_cache = {}
    end

    alias fresh_cache clear_cache

    def close
      ensure_disconnected
      clear_cache
    end

    def common_key_prefix
      "XAMPL::#{ @repo_name }::"
    end

    def key_for_class(klass, index)
      #NOTE -- the XAMPL::#{ @repo_name }:: is a prefix common to all keys specific to this repository
      "#{ common_key_prefix }#{ klass.persistence_class.name }[#{ index }]"
    end

    def key_for_xampl(xampl)
      key_for_class(xampl.class, xampl.get_the_index)
    end

    def known_repos
      return @client.smembers(REPOSITORIES_KEY)
    end

    def perm_cache(xampl)
      raise NotXamplPersistedObject.new(xampl) unless xampl.kind_of?(XamplPersistedObject)

      key = key_for_xampl(xampl)
      existing = @cache[key]

      begin
#        raise DuplicateXamplInPersister.new(existing, xampl, self) if existing && (existing.weakref_alive?) && (existing.__getobj__ != xampl)
        raise DuplicateXamplInPersister.new(existing, xampl, self) if existing && (existing.__getobj__ != xampl)
      rescue WeakRef::RefError => e
        # key is there but the original object isn't...
      end

      @cache[key] = WeakRef.new(xampl)
    end

    def perm_uncache(xampl)
      raise NotXamplPersistedObject.new(xampl) unless xampl.kind_of?(XamplPersistedObject)

      key = key_for_xampl(xampl)
      @cache.delete(key).__getobj__
    end

    def cache(xampl)
      # this is called by xampl for the temporary new_cache
      raise NotXamplPersistedObject.new(xampl) unless xampl.kind_of?(XamplPersistedObject)

      key = key_for_xampl(xampl)

      existing = @new_cache[key]
      raise DuplicateXamplInPersister.new(existing, xampl, self) if existing && (existing != xampl)

      existing = @cache[key]
      begin
#        raise DuplicateXamplInPersister.new(existing, xampl, self) if existing && (existing.weakref_alive?) && (existing.__getobj__ != xampl)
        raise DuplicateXamplInPersister.new(existing, xampl, self) if existing && (existing.__getobj__ != xampl)
      rescue WeakRef::RefError => e
        # key is there but the original object isn't...
      end

      @new_cache[key] = xampl
    end

    def uncache(xampl)
      # this is called by xampl for the temporary new_cache
      raise NotXamplPersistedObject.new(xampl) unless xampl.kind_of?(XamplPersistedObject)

      key = key_for_xampl(xampl)
      @new_cache.delete(key)
    end

    def in_perm_cache?(klass, index)
      key = key_for_class(klass, index)
      xampl = @cache[key]

      (xampl && xampl.weakref_alive?) ? true : false
    end

    alias in_cache? in_perm_cache?

    def in_new_cache?(klass, index)
      key = key_for_class(klass, index)
      @new_cache.include?(key)
    end

    def in_any_cache?(klass, index)
      in_new_cache?(klass, index) || in_cache?(klass, index)
    end

    def read_from_cache(klass, index, target=nil)

      key = key_for_class(klass, index)

      xampl = @cache[key]
      begin
        xampl = xampl.__getobj__ if xampl
      rescue WeakRef::RefError => e
        #not there
        xampl = nil
      end
#      xampl = (xampl && xampl.weakref_alive?) ? xampl.__getobj__ : nil

      unless xampl then
        xampl = @new_cache[key]
      end

      return nil, target unless xampl

      if target and target != xampl then
        puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] TEST ME"
        target.invalidate
        raise XamplException.new(:cache_conflict)
      end
      unless xampl.load_needed then
        @cache_hits = @cache_hits + 1
        return xampl, target
      end
      return xampl, xampl
    end

    def sync_done
      # simply moves the new_cache to the permanent cache
      (@new_cache || {}).each do |key, xampl|
        @cache[key] = WeakRef.new(xampl)
      end
      @new_cache = {}
    end

    def write(xampl)
      unless xampl.get_the_index
        puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] TEST ME"
        raise NotXamplPersistedObject.new(xampl)
      end

      #TODO -- honour the mentions config information (FROM THE DB not the configuration!!)
      mentions = []
      xml = represent(xampl, mentions)
      key = key_for_xampl(xampl)

      #TODO save the modified-time-like value to support multi processing

#      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] redis #{ self }"
#      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] write: #{ xampl } --> #{ xml }"
#      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] key: #{ key }"

      client.set(key, xml)
      @write_count = @write_count + 1
      xampl.changes_accepted
      return true

    rescue NotXamplPersistedObject => nxpo
      raise nxpo
    rescue => e
      puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] #{ e }"
      puts e.backtrace
      return false
    end

    def read(klass, pid, target=nil)
      xampl, target = read_from_cache(klass, pid, target)
      return xampl if xampl and !target

      key = key_for_class(klass, pid)
      xml = client.get(key)
      unless xml
        puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] TEST ME"
        return nil
      end

      xampl = realise(xml, target)
      Xampl.store_in_cache(@cache, xampl, self) { xampl }
      xampl.introduce_persister(self)

      @read_count = @read_count + 1
      xampl.changes_accepted
      @changed.delete(xampl)
      return xampl
    end

    def rollback_cleanup

      @new_cache.each { |name, xampl|
        if xampl then
          @changed.delete(xampl)
          xampl.invalidate

#          map.each { |name2, map2|
#            if map2 then
#              map2.each { |pid, xampl|
#                @changed.delete(xampl)
#                xampl.invalidate
#              }
#            end
#          }
        end
      }
      @changed.each { |xampl, ignore|
        xampl.force_load
      }
      @new_cache = {}

      super
    end

=begin






  def backup(base_path)
    #TODO
  end

  def do_sync_write
    #TODO
  end

  def done_sync_write
    #TODO
  end

  def expunge(xampl)
    #TODO
  end

  def find_mentions_of(xampl)
    #TODO
  end

  def find_meta(hint=false)
    #TODO
  end

  def find_pids(hint=false)
    #TODO
  end

  def find_xampl(hint=false)
    #TODO
  end

  def how_indexed(xampl)
    #TODO
  end

  def inspect
    #TODO
  end

  def note_errors(msg="TokyoCabinet Error:: %s\n")
    #TODO
  end

  def open_tc_db
    #TODO
  end

  def optimise(opts={})
    #TODO
  end

  def query(hint=false)
    #TODO
  end

  def query_implemented
    #TODO
  end

  def read_representation(klass, pid)
    #TODO
  end

  def remove_all_mention(root, xampl)
    #TODO
  end

  def setup_db
    #TODO
  end

  def start_sync_write
    #TODO
  end

  def to_s
    #TODO
  end

=end

  end


  Xampl.register_persister_kind(RedisPersister)
end

