module Xampl

  module XamplPersistedObject
    include XamplObject

    attr_reader :persister
    attr_accessor :load_needed

    def persist_required
      return true
    end

    def accessed
      raise XamplIsInvalid.new(self) if invalid
      # TODO -- why do I need to get rid of this line, alternatively, why
      # is this next line even there? Well, because accessed is now called
      # differently. But???
      #raise NoActivePersister unless @persister

      if @load_needed and @persister then
        raise NoActivePersister.new unless @persister

        if nil == Xampl.persister then
          #raise UnmanagedChange.new(self)
          if not @persister.syncing then
            Xampl.read_only(@persister) do
              Xampl.lazy_load(self)
            end
          else
            puts "LOAD NEEDED(2): REFUSED (persister: #{@persister.name})"
            puts "                pid: #{self.get_the_index} #{self}"
            caller(0).each { | trace | puts "  #{trace}"}
          end
        elsif Xampl.persister != @persister then
          raise MixedPersisters.new(@persister, self)
        elsif Xampl.persister == @persister then
          if not @persister.syncing then
            Xampl.lazy_load(self)
          else
            puts "LOAD NEEDED(3): BAD IDEA, but load anyway (persister: #{@persister.name})"
            puts "                #{self.class.name}"
            puts "                pid: #{self.get_the_index}"
            Xampl.lazy_load(self)
#            puts "LOAD NEEDED(3): REFUSED (persister: #{@persister.name})"
#            puts "                #{self.class.name}"
#            puts "                pid: #{self.get_the_index}"
#            caller(0).each { | trace | puts "  #{trace}"}
          end
        else
          puts "LOAD NEEDED(4): REFUSED (persister: #{@persister.name})"
          puts "                pid: #{self.get_the_index} #{self}"
          caller(0).each { | trace | puts "  #{trace}"}
        end
      else
        puts "LOAD NEEDED(5): REFUSED (persister: #{@persister})" if @load_needed
        puts "                pid: #{self.get_the_index} #{self}" if @load_needed
        caller(0).each { | trace | puts "  #{trace}"} if @load_needed
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
