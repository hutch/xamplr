module Xampl

  module XamplPersistedObject
    include XamplObject

    attr_reader :persister
    attr_accessor :load_needed
    attr_accessor :must_be_mentioned

    def persist_required
      return true
    end

    def accessed
      return unless @load_needed

      raise XamplIsInvalid.new(self) if invalid
      raise NoActivePersister.new unless @persister
      raise XamplException(:load_blocked_because_persister_is_syncing,
                           "often happens when you are describing a xampl object using a different persisted xampl object that hasn't been loaded yet") if @persister.syncing

      Xampl.read_only(@persister) do
        Xampl.lazy_load(self)
      end
    end

    def changed?
      @is_changed = true
    end

    def changed
#      puts "CHANGED: is_changed #{@is_changed} xampl #{self}"
      unless Xampl.persister then
        raise UnmanagedChange.new(self)
      end
      if @persister then
        if Xampl.persister != @persister then
          raise UnmanagedChange.new(self)
        end
        if @persister.block_changes then
          raise BlockedChange.new(self)
        end
      end
      unless @is_changed then
        @is_changed = true
        if @persister then
          @persister.has_changed self
        end
      end
    end

    def force_load
      @load_needed = true
      @is_changed = false
      @persister.has_not_changed(self) if @persister
      self.clear_non_persistent_index_attributes
      methods = self.methods.grep(/init_.*_as_child/)
      methods.each do |method_name|
        self.send(method_name)
      end
      @children = []
    end

    def reset_contents
      self.clear_non_persistent_index_attributes
      self.methods.grep(/init_.*_as_child/).each do |method_name|
        self.send(method_name)
      end
      @children = []
    end

    def introduce_persister(persister)
      #accessed
      if @persister and (@persister != persister) then
        raise AlreadyKnownToPersister.new(self, persister)
      end
      @persister = persister
      return true
    end

    def init_xampl_object
      super
      @persister = nil
      @load_needed = false
      if (Xampl.persister and Xampl.persister.automatic) then
        Xampl.persister.introduce(self)
      else
        introduce_persister(nil)
      end
    end

    def describe_yourself
      nil
    end
  end

end
