module Xampl

  class SimplePersister < Persister

    def initialize(name=nil, format=nil, ignore=nil)
      super(name, format)

      @module_map = {}
      @cache = {}
    end

    def SimplePersister.kind
      :simple
    end

    def kind
      SimplePersister.kind
    end

    def sync_done
    end

    def has_changed(xampl)
      throw :mixed_persisters unless self == xampl.persister
    end

    def cache(xampl)
      return Xampl.store_in_map(@cache, xampl) { xampl }
    end

    def uncache(xampl)
    end

    def clear_cache
      throw :really_bad_idea, "clearing the cache in a simple persister looses information"
    end

    def write(xampl)
      return true
    end

    def read(klass, pid, target=nil)
      xampl = Xampl.lookup_in_map(@cache, klass, pid)

      if (nil != xampl) then
        if target and target != xampl then
          target.invalidate
          throw(:cache_conflict)
        end
        throw(:load_unsupported) if xampl.load_needed
      end

      return xampl
    end
  end

  Xampl.register_persister_kind(SimplePersister)
end

