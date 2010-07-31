module Xampl

  class XamplIsInvalid < Exception
    attr_reader :msg, :xampl

    def initialize(xampl)
      @xampl = xampl
      @msg = "Invalid Xampl:: #{xampl}"
    end

    def message
      @msg
    end
  end

  class AlreadyKnownToPersister < Exception
    attr_reader :msg, :xampl

    def initialize(xampl, persister)
      @xampl = xampl
      @msg = "#{xampl} #{xampl.get_the_index} is already known by a persister: #{xampl.persister.name}, so cannot use persister #{persister.name}"
    end

    def message
      @msg
    end
  end

  class AlreadyKnownToPersister < Exception
    attr_reader :msg, :xampl

    def initialize(xampl, persister)
      @xampl = xampl
      @msg = "#{xampl} #{xampl.get_the_index} is already known by a persister: #{xampl.persister.name}, so cannot use persister #{persister.name}"
    end

    def message
      @msg
    end
  end

  class DuplicateXamplInPersister < Exception
    attr_reader :msg

    def initialize(xampl1, xampl2, persister)
      @msg = "index: '#{ xampl1.get_the_index }', persister: #{ persister.name }, first: #{ xampl1 }, second: #{ xampl2 }"
    end

    def message
      @msg
    end
  end

  class AlreadyKnownToPersister < Exception
    attr_reader :msg, :xampl

    def initialize(xampl, persister)
      @xampl = xampl
      @msg = "#{xampl} #{xampl.get_the_index} is already known by a persister: #{xampl.persister.name}, so cannot use persister #{persister.name}"
    end

    def message
      @msg
    end
  end

  class XamplException < Exception
    attr_reader :name, :msg

    def initialize(name, message=nil)
      @name = name
      @msg = message ? message : ""
    end

    def message
      "XamplException #{@name} #{@msg}"
    end
  end

  class NoActivePersister < Exception
    def message
      "No Persister is active"
    end
  end

  class NoAnonymousPersisters < Exception
    def message
      "All persisters must be named"
    end
  end

  class NoPersisterNamed < Exception
    attr_reader :name

    def initialize(name=nil)
      @name = name
    end

    def message
      if name then
        "there is no persister named: '#{ @name }'"
      else
        "no name was supplied"
      end
    end
  end

  class NotXamplPersistedObject < Exception
    attr_reader :klass

    def initialize(thing=nil)
      @klass = thing.class.name
    end

    def message
      "require a XamplPersistedObject, got a #{ klass }"
    end
  end

  class BlockedChange < Exception
    attr_reader :xampl

    def initialize(xampl=nil)
      @xampl = xampl
    end

    def message
      "attempt to change #{@xampl}, pid: #{@xampl.get_the_index}, oid: #{@xampl.object_id} when changes are blocked"
    end
  end

  class ReturnOrThrowInTransaction < Exception
    attr_reader :xampl

    def initialize(xampl=nil)
      @xampl = xampl
    end

    def message
      "attempt to change #{@xampl}, pid: #{@xampl.get_the_index}, oid: #{@xampl.object_id} when changes are blocked"
    end
  end

  class UnexpectedExitFromTransaction < Exception
    attr_reader :xampl

    def initialize(xampl=nil)
      @xampl = xampl
    end

    def message
      "unexpected exit from a transaction: ROLLBACK"
    end
  end

  class UnmanagedChange < Exception
    attr_reader :xampl

    def initialize(xampl=nil)
      @xampl = xampl
    end

    def message
      "attempt to change #{@xampl}, pid: #{@xampl.get_the_index}, oid: #{@xampl.object_id} outside of its persister's management"
    end
  end

  class IncompatiblePersisterRequest < Exception
    attr_reader :msg

    def initialize(persister, feature_name, requested_feature_value, actual_feature_value)
      @msg = "persister #{persister.name}:: requested feature: #{feature_name} #{requested_feature_value}, actual: #{actual_feature_value}"
    end

    def message
      @msg
    end
  end

  class IncompatiblePersisterConfiguration < Exception
    attr_reader :msg

    def initialize(persister_kind, feature_name)
      @msg = "persister kind #{persister_kind}:: requested feature: #{feature_name}"
    end

    def message
      @msg
    end
  end

  class MixedPersisters < Exception
    attr_reader :msg

    def initialize(active, local)
      @msg = "mixed persisters:: active #{active.name}/#{ active }, local: #{local.name}/#{ local }"
    end

    def message
      @msg
    end
  end

end
