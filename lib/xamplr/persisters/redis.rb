module Xampl

#  require "xamplr/persisters/caches"

  require 'weakref'

  class RedisPersister < Persister

    # TC has these persister options:
    # TODO -- do something reasonable with these options??
#    tokyo-cabinet.rb:        if Xampl.raw_persister_options[:otsync] then
#    tokyo-cabinet.rb:        if Xampl.raw_persister_options[:mentions] then
#    tokyo-cabinet.rb:            if Xampl.raw_persister_options[:write_through] then

    attr_accessor :mentions, # if true, keep track of other persisted objects mentioned by a persisted object
                  :db, # which db in redis to use (0 is the default, as it is in redis)
                  :repo_name

    @@default_options = {
            :mentions => false,
            :db => 0
    }

    def initialize(name=nil, format=nil, options={})
      super(name, format)

      @repo_name = name
      @cache = {}

#      options = @@default_options.merge Xampl.raw_persister_options.merge options
#
#      @mentions = options[:mentions]
#      @db = options[:db]

      #TODO
      # connect to the redis db specified in options, or failing that the raw persister options
      # find options for the persister in the current redis DB

=begin

      @module_map = {}
      @capacity = capacity
      @cache = {}
      @new_cache = {}

=end
    end

    def RedisPersister.kind
      :redis
    end

    def kind
      RedisPersister.kind
    end

    def connect
      return if redis

      raise "piss off"
    end

    def disconnect
      return unless redis

      raise "piss off"
    end

    def redis
      @connection
    end

    def close
      disconnect
      clear_cache
    end

    def clear_cache
      @cache = {}
    end

    alias fresh_cache clear_cache

    def key_for_class(klass, index)
      "XAMPL::#{ @repo_name }::#{ klass.name }[#{ index }]"
    end

    def key_for_xampl(xampl)
      key_for_class(xampl.class, xampl.get_the_index)
    end

    def cache(xampl)
      raise NotXamplPersistedObject.new(xampl) unless xampl.kind_of?(XamplPersistedObject)

      key = key_for_xampl(xampl)
      existing = @cache[key]

      raise DuplicateXamplInPersister.new(existing, xampl, self) if existing && (existing.weakref_alive?) && (existing.__getobj__ != xampl)

      @cache[key] = WeakRef.new(xampl)
    end

    def uncache(xampl)
      raise NotXamplPersistedObject.new(xampl) unless xampl.kind_of?(XamplPersistedObject)

      key = key_for_xampl(xampl)
      @cache.delete(key).__getobj__
    end

    def read_from_cache(klass, index, target=nil)

      key = key_for_class(klass, index)

      xampl = @cache[key]
      return (xampl && xampl.weakref_alive?) ? xampl.__getobj__ : nil
=begin

TODO -- do we need this stuff??
      xampl = Xampl.lookup_in_map(@cache, klass, pid)
      if xampl then
        if target and target != xampl then
          target.invalidate
          raise XamplException.new(:cache_conflict)
        end
        unless xampl.load_needed then
          @cache_hits = @cache_hits + 1
          return xampl, target
        end
        return xampl, xampl
      end

      xampl = Xampl.lookup_in_map(@new_cache, klass, pid)
      if xampl then
        if target and target != xampl then
          target.invalidate
          raise XamplException.new(:cache_conflict)
        end
        unless xampl.load_needed then
          @cache_hits = @cache_hits + 1
          return xampl, target
        end
        return xampl, xampl
      end

      return nil, target

=end
    end


=begin


    def sync_done
      if @new_cache then
        @new_cache.each { |name1, map1|
          if map1 then
            cache_map1 = @cache[name1]
            @cache[name1] = cache_map1 = {} unless cache_map1
            map1.each { |name2, map2|
              if map2 then
                cache_map2 = cache_map1[name2]
                cache_map1[name2] = cache_map2 = self.fresh_cache unless cache_map2

                map2.each { |pid, xampl|
                  cache_map2[pid] = xampl
                }
              end
            }
          end
        }
      end
      @new_cache = {}
    end

    def rollback_cleanup
      @new_cache.each { |name, map|
        if map then
          map.each { |name2, map2|
            if map2 then
              map2.each { |pid, xampl|
                @changed.delete(xampl)
                xampl.invalidate
              }
            end
          }
        end
      }
      @changed.each { |xampl, ignore|
        xampl.force_load
      }
      @new_cache = {}
      super
    end

    def write(xampl)
      raise XamplException.new(:no_index_so_no_persist) unless xampl.get_the_index
      #return false unless xampl.get_the_index

      if Xampl.store_in_map(@module_map, xampl) { represent(xampl) } then
        @write_count = @write_count + 1
        xampl.changes_accepted
        return true
      else
        return false
      end
    end

    def read_from_cache(klass, pid, target=nil)
      xampl = Xampl.lookup_in_map(@cache, klass, pid)
      if xampl then
        if target and target != xampl then
          target.invalidate
          raise XamplException.new(:cache_conflict)
        end
        unless xampl.load_needed then
          @cache_hits = @cache_hits + 1
          return xampl, target
        end
        return xampl, xampl
      end

      xampl = Xampl.lookup_in_map(@new_cache, klass, pid)
      if xampl then
        if target and target != xampl then
          target.invalidate
          raise XamplException.new(:cache_conflict)
        end
        unless xampl.load_needed then
          @cache_hits = @cache_hits + 1
          return xampl, target
        end
        return xampl, xampl
      end

      return nil, target
    end

    def read(klass, pid, target=nil)
      xampl, target = read_from_cache(klass, pid, target)
      return xampl if xampl and !target

      representation = Xampl.lookup_in_map(@module_map, klass, pid)
      return nil unless representation

      xampl = realise(representation, target)
      Xampl.store_in_cache(@cache, xampl, self) { xampl }
      xampl.introduce_persister(self)

      @read_count = @read_count + 1
      xampl.changes_accepted
      @changed.delete(xampl)
      return xampl
    end
  end


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

