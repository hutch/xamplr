module Xampl

  class DumbPersister < Persister

    def initialize(name=nil, format=nil)
      super(name, format)

      @module_map = {}
      @cache = {}
    end

    def DumbPersister.kind
      :dumb
    end

    def kind
      DumbPersister.kind
    end

    def sync_done
    end

    def has_changed(xampl)
      throw :mixed_persisters unless self == xampl.persister
    end

    def cache(xampl)
      xampl
    end

    def uncache(xampl)
    end

    def clear_cache
    end

    def read_from_cache(klass, pid, target=nil)
      return nil, target
    end

    def write(xampl)
      return true
    end

    def read(klass, pid, target=nil)
      return nil
    end
  end

  Xampl.register_persister_kind(DumbPersister)
end

