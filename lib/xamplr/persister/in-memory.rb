module Xampl

  require "xamplr/persister/caches"

  class InMemoryPersister < Persister

    def initialize(name=nil, format=nil, capacity=20)
      super(name, format)

      @module_map = {}
      @capacity = capacity
      @cache = {}
      @new_cache = {}
    end

    def InMemoryPersister.kind
      :in_memory
    end

    def kind
      InMemoryPersister.kind
    end

    def fresh_cache
      return XamplCache.new(@capacity)
    end

    def sync_done
      if @new_cache then
        @new_cache.each{ | name1, map1 |
          if map1 then
            cache_map1 = @cache[name1]
            @cache[name1] = cache_map1 = {} unless cache_map1
            map1.each{ | name2, map2 |
              if map2 then
                cache_map2 = cache_map1[name2]
                cache_map1[name2] = cache_map2 = self.fresh_cache unless cache_map2

                map2.each{ | pid, xampl |
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
      @new_cache.each{ | name, map |
        if map then
          map.each{ | name2, map2 |
            if map2 then
              map2.each{ | pid, xampl |
                @changed.delete(xampl)
                xampl.invalidate
              }
            end
          }
        end
      }
      @changed.each{ | xampl, ignore|
        xampl.force_load
      }
      @new_cache = {}
      super
    end

    def cache(xampl)
      return Xampl.store_in_map(@new_cache, xampl) { xampl }
    end

    def uncache(xampl)
      @changed.delete(xampl)
      Xampl.remove_from_map(@cache, xampl)
      return Xampl.remove_from_map(@new_cache, xampl)
    end

    def clear_cache
      @new_cache = {}
      @cache = {}
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

    def xxread_from_cache(klass, pid, target=nil)
      xampl = Xampl.lookup_in_map(@cache, klass, pid)
      if (nil != xampl) then
        puts "READ CACHE pid #{pid} -- #{target} #{xampl}" if target and  target != xampl
        if target and target != xampl then
          target.invalidate
          raise XamplException.new(:cache_conflict)
        end
        unless xampl.load_needed then
          @cache_hits = @cache_hits + 1
          return xampl
        end
        target = xampl
      end

      xampl = Xampl.lookup_in_map(@new_cache, klass, pid)
      if (nil != xampl) then
        puts "READ CACHE pid #{pid} -- #{target} #{xampl}" if target and  target != xampl
        if target and target != xampl then
          target.invalidate
          raise XamplException.new(:cache_conflict)
        end
        unless xampl.load_needed then
          @cache_hits = @cache_hits + 1
          return xampl
        end
        target = xampl
      end

      return xampl
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

  Xampl.register_persister_kind(InMemoryPersister)
end

