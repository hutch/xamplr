module Xampl

  require "fileutils"
  require "xamplr/persister/caches"

  class AbstractCachingPersister < Persister

    def initialize(root, name=nil, format=nil, capacity=DEFAULT_CAPACITY)
      super(name, format)

      raise XamplException.new(:name_required) unless name

      @root_dir = File.join(root, name)
      @repo_root = root
      @repo_name = name

      @capacity = capacity
      @cache = {}
      @new_cache = {}
    end

    def fresh_cache
      return XamplCache.new(@capacity)
    end

    def sync_done
      if @new_cache then
        @new_cache.each do |name1, map1|
          if map1 then
            cache_map1 = @cache[name1]
            @cache[name1] = cache_map1 = {} unless cache_map1
            map1.each do |name2, map2|
              if map2 then
                cache_map2 = cache_map1[name2]
                #cache_map1[name2] = cache_map2 = {} unless cache_map2
                cache_map1[name2] = cache_map2 = fresh_cache unless cache_map2

                #cache_map2.merge!(map2)
                map2.each do |pid, xampl|
                  cache_map2[pid] = xampl
                end
              end
            end
          end
        end
      end
      @new_cache = {}
    end

    def rollback_cleanup
      @new_cache.each do |name, map|
        if map then
          map.each do |name2, map2|
            if map2 then
              map2.each do |pid, xampl|
                @changed.delete(xampl)
              end
            end
          end
        end
        @changed.each do |xampl, ignore|
          xampl.force_load
        end
        @new_cache = {}
        super
      end
    end

    def cache(xampl)
      Xampl.store_in_map(@new_cache, xampl) { xampl }
      xampl.introduce_persister(self)
    end

    def uncache(xampl)
      @changed.delete(xampl)
      Xampl.remove_from_map(@cache, xampl)
      return Xampl.remove_from_map(@new_cache, xampl)
    end

    def clear_cache
      @cache = {}
      @new_cache = {}
    end

    def write_to_cache(xampl)
      # puts "WRITE TO CACHE (#{xampl})"
      return Xampl.store_in_cache(@cache, xampl, self) { xampl }
    end

    def read_from_cache(klass, pid, target=nil)
      xampl = Xampl.lookup_in_map(@cache, klass, pid)
      if xampl then
        if target and target != xampl then

          puts "#{File.basename(__FILE__)} #{__LINE__} CACHE CONFLICT:: klass: #{ klass }, pid: #{ pid }, target: #{ target }, cached: #{ xampl }"
          dump(@cache)
          caller(0).each { | trace | puts "  #{trace}"}

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

    def dump(cache)
      puts "DUMP CACHE"
      cache.each do | k, v |
        puts "--- [[#{k}]]"
        v.each do | kk, vv |
          puts "--- --- [[#{kk}]]"
          puts vv.print
        end
      end
    end

    def read(klass, pid, target=nil)
      #      puts "#{File.basename(__FILE__)} #{__LINE__} READ:: klass: #{klass} pid: #{pid} target: [[#{target}]], PM: #{ self }"

      xampl, target = read_from_cache(klass, pid, target)
      return xampl if xampl and !target

      representation = read_representation(klass, pid)
      return nil unless representation

      xampl = nil
      begin
        #puts "ABSTRACT_READ[#{__LINE__}]:: klass: #{klass} pid: #{pid} target: #{target}"
        xampl = realise(representation, target)
        return nil unless xampl
      rescue Exception => e
        puts "FAILED TO READ -- persister: #{name} klass: #{klass} pid: #{pid} target: #{target}"
        puts "Exception: #{e}"
        print e.backtrace.join("\n")
        #sleep 10
        raise e
      end

      #      puts "#{File.basename(__FILE__)} #{__LINE__} STORE IN CACHE:: xampl: #{xampl }, persister: #{ self }"
      #      dump(@cache)

      Xampl.store_in_cache(@cache, xampl, self) { xampl }
      xampl.introduce_persister(self)

      @read_count = @read_count + 1
      xampl.changes_accepted
      @changed.delete(xampl)

      return xampl
    end
  end
end

