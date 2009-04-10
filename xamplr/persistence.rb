#!/usr/bin/env ruby

require 'sync'

module Xampl

  @@persister = nil
  @@known_persisters = {}
  @@persister_kinds = {}

  def Xampl.persister
    @@persister
  end

  def Xampl.block_future_changes(on=true)
    if (@@persister) then
      @@persister.block_changes = on
    end
  end

  def Xampl.auto_persistence(on=true)
    if (@@persister) then
      @@persister.automatic = on
    end
  end

  def Xampl.register_persister_kind(klass)
    @@persister_kinds[klass.kind] = klass
  end

  def Xampl.disable_all_persisters
    @@persister = nil
    @@known_persisters = {}
  end

  def Xampl.disable_persister
    @@persister = nil
  end

  @@default_persister_kind = :simple
  @@default_persister_format = :xml_format

  def Xampl.default_persister_kind
    @@default_persister_kind
  end
  def Xampl.set_default_persister_kind(kind)
    @@default_persister_kind = kind
    #puts "SET KIND format: #{@@default_persister_format}, kind: #{@@default_persister_kind}"
  end

  def Xampl.default_persister_format
    @@default_persister_format
  end
  def Xampl.set_default_persister_format(format)
    @@default_persister_format = format
    #puts "SET FORMAT format: #{@@default_persister_format}, kind: #{@@default_persister_kind}"
  end

  def Xampl.enable_persister(name, kind=nil, format=nil)
    kind = kind || @@default_persister_kind
    format = format || @@default_persister_format
    @@persister = @@known_persisters[name]

    if @@persister then
      # TODO -- if we know the persister, why are we being so anal about kind and format???

      kind = @@persister.kind || kind
      format = @@persister.format || format

      #raise XamplException.new(:live_across_rollback) if @@persister.rolled_back
      if kind and kind != @@persister.kind then
        raise IncompatiblePersisterRequest.new(@@persister, "kind", kind, @@persister.kind)
      end
      if format and format != @@persister.format then
        raise IncompatiblePersisterRequest.new(@@persister, "format", format, @@persister.format)
      end
    end

    unless @@persister then
      # puts "CREATE PERSISTER #{name}, format: #{format}, kind: #{kind}"
      @@persister = @@persister_kinds[kind].new(name, format)
      if (nil != name) then
        @@known_persisters[name] = @@persister
      end
    end

    @@persister
  end

  def Xampl.print_known_persisters
    puts "Known Persisters:: --------------------------"
    @@known_persisters.each { | n, k |
      puts "    #{n} #{k}"
    }
    puts "---------------------------------------------"
  end

  def Xampl.flush_persister_caches
    Xampl.print_known_persisters
    @@known_persisters.delete(@@persister.name)
    Xampl.print_known_persisters
  end

  def Xampl.drop_all_persisters
    puts "Drop All Persisters:: --------------------------"
    @@known_persisters.each { | n, k |
      puts "    #{n} #{k}"
    }
    puts "---------------------------------------------"
    @@known_persisters = {}
    GC.start
    GC.start
    GC.start
  end

  def Xampl.drop_persister(name)
    Xampl.print_known_persisters
    @@known_persisters.delete(name)
    Xampl.print_known_persisters
  end

  @@xampl_lock = Sync.new

  @@verbose_transactions = true
  def Xampl.verboseTransactions(v)
    @@verbose_transactions = v
  end

  def Xampl.transaction(thing, kind=nil, automatic=true, format=nil, &block)
    if String === thing then
      name = thing
    elsif XamplObject === thing then
      name = thing.persister.name
    else
      raise XamplException.new("can't base a transaction on a #{thing.class.name} (#{thing})")
    end

    if block_given? then
      @@xampl_lock.synchronize(:EX) do
        initial_persister = @@persister
        Xampl.enable_persister(name, kind, format)

        rollback = true
        exception = nil
        original_automatic = @@persister.automatic
        begin
          #TODO -- impose some rules on nested transactions/enable_persisters??
          Xampl.auto_persistence(automatic)
          result = yield
          Xampl.block_future_changes(true)
          Xampl.sync
          rollback = false
          return result
        rescue => e
          exception = e
        ensure
          Xampl.block_future_changes(false)
          Xampl.auto_persistence(original_automatic)
          if rollback then
            if exception then
              puts "ROLLBACK(#{__LINE__}):: #{exception}" if rollback and @@verbose_transactions
              #print exception.backtrace.join("\n") if rollback
              raise exception
            else
              if @@verbose_transactions and rollback then
                puts "ROLLBACK(#{__LINE__}):: UNKNOWN CAUSE" if rollback
              end
            end
          end
          Xampl.rollback if rollback
          @@persister = initial_persister
        end
      end
    end
  end

  def Xampl.read_only_transaction(thing, kind=nil, automatic=true, format=nil, &block)
    if String === thing then
      name = thing
    elsif XamplObject === thing then
      name = thing.persister.name
    else
      raise XamplException.new("can't base a transaction on a #{thing.class.name} (#{thing})")
    end

    target_persister = nil
    if block_given? then
      @@xampl_lock.synchronize(:EX) do
        initial_persister = @@persister
        Xampl.enable_persister(name, kind, format)
        target_persister = @@persister

        rollback = true
        original_automatic = @@persister.automatic
        @changed ||= nil
        original_changed = @changed
        @changed = {}
        begin
          Xampl.auto_persistence(false)
          #Xampl.block_future_changes(true)

          yield
          rollback = false
        rescue => e
          exception = e
        ensure
          Xampl.auto_persistence(original_automatic)
          #Xampl.block_future_changes(false)

          if 0 == @changed.size then
            @changed = original_changed

            if rollback then
              puts "ROLLBACK(#{__LINE__}):: #{exception}"
              print exception.backtrace.join("\n")
              Xampl.rollback
            end
            @@persister = initial_persister
          else
            puts "CHANGED COUNT: #{@changed.size}"
            @changed = original_changed

            puts "ROLLBACK(#{__LINE__}) #{exception}" if rollback
            print exception.backtrace.join("\n")
            Xampl.rollback

            @@persister = initial_persister

            raise BlockedChange.new(target_persister)
          end
        end
      end
    end
  end

  def Xampl.read_only(target_persister)
    #TODO -- EXCLUSIVE ACCESS TO THE PERSISTER!!!
    name = target_persister.name

    if block_given? then
      initial_persister = @@persister
      Xampl.enable_persister(name, target_persister.kind, target_persister.format)

      rollback = true
      original_automatic = @@persister.automatic
      original_changed = @changed
      @changed = {}
      begin
        Xampl.auto_persistence(false)
        #Xampl.block_future_changes(true)

        yield
        rollback = false
      ensure
        ####        Xampl.auto_persistence(original_automatic)
        ####        #Xampl.block_future_changes(false)
        ####
        ####        if 0 < @changed.size then
        ####          puts "CHANGED COUNT: #{@changed.size}"
        ####          raise BlockedChange.new(target_persister)
        ####        end
        ####
        ####        @changed = original_changed
        ####
        ####        puts "ROLLBACK(#{__LINE__})" if rollback
        ####			  Xampl.rollback if rollback
        ####	      @@persister = initial_persister

        Xampl.auto_persistence(original_automatic)
        #Xampl.block_future_changes(false)

        if 0 == @changed.size then
          @changed = original_changed

          puts "ROLLBACK(#{__LINE__})" if rollback
          Xampl.rollback if rollback
          @@persister = initial_persister
        else
          puts "CHANGED COUNT: #{@changed.size}"
          @changed = original_changed

          puts "ROLLBACK(#{__LINE__})" if rollback
          Xampl.rollback

          @@persister = initial_persister

          raise BlockedChange.new(target_persister)
        end
      end
    end
  end

  def Xampl.introduce_to_persister(xampl)
    @@persister.introduce(xampl) if @@persister
  end

  def Xampl.count_changed
    @@persister.count_changed if @@persister
  end

  def Xampl.print_stats
    @@persister.print_stats if @@persister
  end

  def Xampl.auto_cache(xampl)
    if (nil == xampl.persister) and @@persister and @@persister.automatic then
      xampl.persister = @@persister
    end
    if xampl.persister and xampl.persister.automatic then
      xampl.persister.cache(xampl)
    end
  end

  def Xampl.auto_uncache(xampl)
    if xampl.persister and xampl.persister.automatic then
      xampl.persister.uncache(xampl)
    end
  end

  def Xampl.clear_cache
    @@persister.clear_cache if nil != @@persister
  end

  def Xampl.sync
    #raise XamplException.new(:live_across_rollback) if @@persister.rolled_back
    @@persister.sync if nil != @@persister
  end

  def Xampl.version(stream)
    @@persister.version(stream) if nil != @@persister
  end

  def Xampl.sync_all
    @@known_persisters.each{ | name, persister |
      persister.sync
    }
  end

  def Xampl.rollback(persister=@@persister)
    raise NoActivePersister unless persister
    persister.rollback_cleanup
  end

  def Xampl.rollback_all
    @@known_persisters.values.each{ | persister |
      persister.rollback
    }
  end

  def Xampl.lazy_load(xampl)
    pid = xampl.get_the_index
    if xampl and pid and @@persister then
      @@persister.lazy_load(xampl, xampl.class, pid) if xampl and pid and @@persister
      xampl.load_needed = false
    else
      puts "XAMPL.LAZY_LOAD -- REFUSED"
    end
  end

  def Xampl.lookup(klass, pid)
    @@persister.lookup(klass, pid) if nil != persister
  end

  def Xampl.lookup_lazy(klass, pid)
    # TODO -- Make this work
    puts "LOOKUP LAZY(#{klass.name}, #{pid})"

    xampl = Xampl.find_known(klass, pid)

    puts "LOOKUP LAZY(#{klass.name}, #{pid}) -- EXISTING: #{xampl}"
    return xampl if xampl

    #xampl = @@persister.lookup(klass, pid) if nil != persister
    if nil != persister then
      xampl = klass.new(pid) if nil != persister
      xampl.load_needed = true
    end

    puts "LOOKUP LAZY(#{klass.name}, #{pid}) -- LAZY LOADER: #{xampl}"

    return xampl
  end

  def Xampl.find_known(klass, pid)
    xampl, ignore = @@persister.find_known(klass, pid) if nil != persister
    return xampl
  end

  def Xampl.write_to_cache(xampl)
    @@persister.write_to_cache(xampl)
  end

  def Xampl.cache(xampl)
    @@persister.cache(xampl)
  end

  def Xampl.lookup_in_map(map, klass, pid)
    return nil if nil == pid

    module_name = klass.module_name
    tag = klass.tag

    tag_map = map[module_name]
    return nil if nil == tag_map

    pid_map = tag_map[tag]
    return nil if nil == pid_map

    return pid_map[pid]
  end

  def Xampl.store_in_map(map, xampl)
    module_name = xampl.module_name
    tag = xampl.tag
    pid = xampl.get_the_index

    if nil == pid then
      return false
    end

    if block_given? then
      data = yield
    else
      data = xampl
    end

    tag_map = map[module_name]
    if nil == tag_map then
      tag_map = {}
      map[module_name] = tag_map
    end

    pid_map = tag_map[tag]
    if nil == pid_map then
      pid_map = {}
      tag_map[tag] = pid_map
    end

    pid_map[pid] = data

    return true
  end

  def Xampl.store_in_cache(map, xampl, container)
    module_name = xampl.module_name
    tag = xampl.tag
    pid = xampl.get_the_index

    if nil == pid then
      return false
    end

    if block_given? then
      data = yield
    else
      data = xampl
    end

    tag_map = map[module_name]
    if nil == tag_map then
      tag_map = {}
      map[module_name] = tag_map
    end

    pid_map = tag_map[tag]
    if nil == pid_map then
      pid_map = container.fresh_cache
      tag_map[tag] = pid_map
    end

    pid_map[pid] = data

    return true
  end

  def Xampl.remove_from_map(map, xampl)
    pid = xampl.get_the_index
    return nil unless pid

    tag_map = map[xampl.module_name]
    return nil unless tag_map

    pid_map = tag_map[xampl.tag]
    return nil unless pid_map

    return pid_map.delete(pid)
  end

  class Persister
    attr_accessor :name,
                  :automatic,
                  :block_changes,
                  :read_count, :total_read_count,
                  :write_count, :total_write_count,
                  :total_sync_count, :total_rollback_count,
                  :cache_hits, :total_cache_hits,
                  :last_write_count,
                  :rolled_back
    attr_reader :syncing, :format

    def initialize(name=nil, format=nil)
      @name = name
      @format = format
      @automatic = false
      @changed = {}
      @cache_hits = 0
      @total_cache_hits = 0
      @read_count = 0
      @total_read_count = 0
      @write_count = 0
      @total_write_count = 0
      @last_write_count = 0
      @total_sync_count = 0
      @total_rollback_count = 0
      @rolled_back = false
      @syncing = false

      @busy_count = 0
    end

    def busy(yes)
      if yes then
        @busy_count += 1
      elsif 0 < @busy_count then
        @busy_count -= 1
      end
    end

    def is_busy
      return 0 < @busy_count
    end

    def introduce(xampl)
      if xampl.introduce_persister(self) then
        cache(xampl)
      end
      has_changed(xampl) if xampl.is_changed
    end

    def has_changed(xampl)
      #raise XamplException.new(:live_across_rollback) if @rolled_back
      # puts "!!!! has_changed #{xampl} #{xampl.get_the_index} -- persist required: #{xampl.persist_required}"
      if xampl.persist_required && xampl.is_changed then
        unless self == xampl.persister
          raise MixedPersisters.new(xampl.persister, self)
        end
        @changed[xampl] = xampl
#         puts "!!!! change recorded ==> #{@changed.size}/#{count_changed} #{@changed.object_id} !!!!"
        #         @changed.each{ | thing, ignore |
        #           puts "             changed: #{thing}, index: #{thing.get_the_index},  changed: #{thing.is_changed}"
        #         }
      end
    end

    def has_not_changed(xampl)
      #       puts "!!!! has_not_changed #{xampl} #{xampl.get_the_index} -- in @changed: #{nil != @changed[xampl]}"
      @changed.delete(xampl) if xampl
    end

    def count_changed
#      @changed.each{ | thing, ignore |
      #        puts "changed: #{thing}, index: #{thing.get_the_index}"
      #      }
      return @changed.size
    end

    def cache(xampl)
      raise XamplException.new(:unimplemented)
    end

    def uncache(xampl)
      raise XamplException.new(:unimplemented)
    end

    def clear_cache
      raise XamplException.new(:unimplemented)
    end

    def Persister.replace(old_xampl, new_xampl)
      pid = old_xampl.get_the_index
      if old_xampl.persister != @@persister then
        raise MixedPersisters.new(@@persister, old_xampl.persister)
      end
      if new_xampl.persister != @@persister then
        raise MixedPersisters.new(@@persister, new_xampl.persister)
      end

      new_xampl.note_replacing(old_xampl)

      unless old_xampl.load_needed then
        Xampl.log.warn("Replacing live xampl: #{old_xampl} pid: #{pid}")
        @@persister.uncache(old_xampl)
        old_xampl.invalidate
      end
      new_xampl.pid = nil
      new_xampl.pid = pid
      @@persister.introduce(new_xampl)
    end

    def represent(xampl)
      #puts "REPRESENT #{xampl} load needed: #{xampl.load_needed}"
      #      return nil if xampl.load_needed
      case xampl.default_persister_format || @format
      when nil, :xml_format then
        return xampl.persist
      when :ruby_format then
        return xampl.to_ruby
      when :yaml_format then
        return xampl.as_yaml
      end
    end

    def realise(representation, target=nil)
      # Normally we'd expect to see the representation in the @format format, but
      # that isn't necessarily the case. Try to work out what the format might be...

      if representation =~ /^</ then
        return XamplObject.realise_from_xml_string(representation, target)
      elsif representation =~ /^-/ then
        return XamplObject.from_yaml(representation, target)
      else
        XamplObject.from_ruby(representation, target)
      end

      # case @format
      #   when nil, :xml_format then
      #     return XamplObject.realise_from_xml_string(representation, target)
      #   when :ruby_format then
      #     XamplObject.from_ruby(representation, target)
      #   when :yaml_format then
      #     return XamplObject.from_yaml(representation, target)
      # end
    end

    def version(stream)
      raise XamplException.new(:unimplemented)
      # catch(:refuse_to_version) do
      # end
    end

    def write(xampl)
      raise XamplException.new(:unimplemented)
    end

    def read(klass, pid, target=nil)
      raise XamplException.new(:unimplemented)
    end

    def lookup(klass, pid)
      #raise XamplException.new(:live_across_rollback) if @rolled_back

      # puts "LOOKUP:: klass: #{klass} pid: #{pid}"

      begin
        busy(true)
        xampl = read(klass, pid)
      ensure
        busy(false)
      end

      return xampl
    end

    def find_known(klass, pid)
      #raise XamplException.new(:live_across_rollback) if @rolled_back

      xampl = read_from_cache(klass, pid, nil)

      return xampl
    end

    def lazy_load(target, klass, pid)
      # puts "LAZY_LOAD:: klass: #{klass} pid: #{pid} target: #{target}"

      xampl = read(klass, pid, target)

      # puts "   LAZY_LOAD --> #{xampl}"

      return xampl
    end

    def put_changed(msg="")
      puts "Changed::#{msg}:"
      @changed.each { | xampl, ignore | puts "   #{xampl.tag} #{xampl.get_the_index}" }
    end

    def do_sync_write
      unchanged_in_changed_list = 0
      @changed.each { | xampl, ignore |
        unchanged_in_changed_list += 1 unless xampl.is_changed
        unless xampl.kind_of?(InvalidXampl) then
          write(xampl)
        end
      }
    end

    def sync
      #raise XamplException.new(:live_across_rollback) if @rolled_back
      begin
        #puts "SYNC"
        #puts "SYNC"
        #puts "SYNC changed: #{@changed.size}" if 0 < @changed.size
        #@changed.each do | key, value |
        ##puts "   #{key.class.name}"
        ##puts "key: #{key.class.name}, value: #{value.class.name}"
        #puts key.to_xml
        #end
        #puts "SYNC"
        #puts "SYNC"

        #if 0 < @changed.size then
        #puts "SYNC changed: #{@changed.size}"
        ##caller(0).each do | trace |
        ##  next if /xamplr/ =~ trace
        ##  puts "  #{trace}"
        ##  break if /actionpack/ =~ trace
        ##end
        #end
        busy(true)
        @syncing = true

        do_sync_write

        @changed = {}

        @total_read_count = @total_read_count + @read_count
        @total_write_count = @total_write_count + @write_count
        @total_cache_hits = @total_cache_hits + @cache_hits
        @total_sync_count = @total_sync_count + 1

        @read_count = 0
        @last_write_count = @write_count
        @write_count = 0

        self.sync_done()

        return @last_write_count
      ensure
        busy(false)
        @syncing = false
      end
    end

    def sync_done
      raise XamplException.new(:unimplemented)
    end

    def rollback
      begin
        busy(true)

        return Xampl.rollback(self)
      ensure
        busy(false)
      end
    end

    def rollback_cleanup
      @changed = {}
    end

    def print_stats
      printf("SYNC:: TOTAL cache_hits: %d, reads: %d, writes: %d\n",
             @total_cache_hits, @total_read_count, @total_write_count)
      printf("             cache_hits: %d, reads: %d, last writes: %d\n",
             @cache_hits, @read_count, @last_write_count)
      printf("             syncs: %d\n", @total_sync_count)
      printf("             changed count: %d (%d)\n", count_changed, @changed.size)
      @changed.each{ | thing, ignore |
        if thing.is_changed then
          puts "             changed: #{thing}, index: #{thing.get_the_index}"
        else
          puts "             UNCHANGED: #{thing}, index: #{thing.get_the_index} <<<<<<<<<<<<<<<<<<< BAD!"
        end
      }
    end
  end

  class NoActivePersister < Exception
    def message
      "No Persister is active"
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

  class MixedPersisters < Exception
    attr_reader :msg

    def initialize(active, local)
      @msg = "mixed persisters:: active #{active.name}, local: #{local.name}"
    end

    def message
      @msg
    end
  end

  require "persister/simple"
  require "persister/in-memory"
  require "persister/filesystem"

  if require 'rufus/tokyo' then
    require "persister/tokyo-cabinet"
  end
end

