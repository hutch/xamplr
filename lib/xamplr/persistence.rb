
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
    @@known_persisters.each { | persister | persister.close}
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
      #      @@persister.open # this won't work
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
    @@known_persisters.each { | n, k | puts "    #{n} #{k}" }
    puts "---------------------------------------------"
  end

  def Xampl.flush_persister_caches
    Xampl.print_known_persisters
    @persister.close
    @@known_persisters.delete(@@persister.name)
    Xampl.print_known_persisters
  end

  def Xampl.drop_all_persisters
    puts "Drop All Persisters:: --------------------------"
    @@known_persisters.each { | n, k | puts "    #{n} #{k}" }
    puts "---------------------------------------------"
    @@known_persisters.each { | persister | persister.close}
    @@known_persisters = {}
    GC.start
    GC.start
    GC.start
  end

  def Xampl.drop_persister(name)
    Xampl.print_known_persisters
    p = @@known_persisters[name]
    p.close if p
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
    raise NoActivePersister unless @@persister

    @@persister.introduce(xampl)
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
    raise NoActivePersister unless @@persister
    @@persister.clear_cache
  end

  def Xampl.sync
    #raise XamplException.new(:live_across_rollback) if @@persister.rolled_back
    raise NoActivePersister unless @@persister
    @@persister.sync
  end

  def Xampl.version(stream)
    @@persister.version(stream) if nil != @@persister
  end

  def Xampl.sync_all
    @@known_persisters.each{ | name, persister | persister.sync }
  end

  def Xampl.close_all_persisters
    @@known_persisters.each do | name, persister |
      persister.close
    end
  end

  def Xampl.rollback(persister=@@persister)
    raise NoActivePersister unless @@persister
    persister.rollback_cleanup
  end

  def Xampl.rollback_all
    @@known_persisters.values.each { | persister | persister.rollback }
  end

  def Xampl.lazy_load(xampl)
    raise NoActivePersister.new unless @@persister

    pid = xampl.get_the_index
    if xampl and pid then
      @@persister.lazy_load(xampl, xampl.class, pid)
      xampl.load_needed = false
    else
      raise "XAMPL.LAZY_LOAD -- REFUSED"
    end
  end

  def Xampl.lookup(klass, pid)
    raise NoActivePersister unless @@persister
    @@persister.lookup(klass, pid)
  end

  def Xampl.find_known(klass, pid)
    raise NoActivePersister unless @@persister
    xampl, ignore = @@persister.find_known(klass, pid)
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

  def Xampl.optimise(opts={})
    raise NoActivePersister unless @@persister

    @@persister.optimise(opts)
  end

  def Xampl.query(hint=false)
    raise NoActivePersister unless @@persister
    @@persister.query(hint) { | q | yield q }
  end

  def Xampl.find_xampl(hint=false)
    raise NoActivePersister unless @@persister
    @@persister.find_xampl(hint) { | q | yield q }
  end

  def Xampl.find_meta(hint=false)
    raise NoActivePersister unless @@persister
    @@persister.find_meta(hint) { | q | yield q }
  end

  def Xampl.find_pids(hint=false)
    raise NoActivePersister unless @@persister
    @@persister.find_pids(hint) { | q | yield q }
  end

  def Xampl.find_mentions_of(xampl)
    raise NoActivePersister unless @@persister
    @@persister.find_mentions_of(xampl)
  end

end

