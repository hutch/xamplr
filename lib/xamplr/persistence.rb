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
    @@known_persisters.each { |persister| persister.close }
    @@known_persisters = {}
  end

  def Xampl.disable_persister
    @@persister = nil
  end

  $is_darwin = RUBY_PLATFORM.include? 'darwin'

  @@factory_default_persister_options = {
          :kind => :simple,
          :format => :xml_format
  }
  @@default_persister_options = {}.merge(@@factory_default_persister_options)

  def Xampl.default_persister_options
    {}.merge(@@default_persister_options)
  end

  def Xampl.raw_persister_options
    @@default_persister_options
  end

  def Xampl.set_default_persister_properties(options)
    if options[:reset] then
      @@default_persister_options = @@factory_default_persister_options.merge(options)
    else
      @@default_persister_options = @@default_persister_options.merge(options)
    end
  end

  def Xampl.default_persister_kind
    @@default_persister_options[:kind]
  end

  def Xampl.set_default_persister_kind(kind)
    @@default_persister_options[:kind] = kind
  end

  def Xampl.default_persister_format
    @@default_persister_options[:format]
  end

  def Xampl.set_default_persister_format(format)
    @@default_persister_options[:format] = format
  end

  def Xampl.create_named_persister(name, kind, arg=nil)
    raise NoAnonymousPersisters.new unless name # there is no such thing as an anonymous persister, maybe later

    persister = @@known_persisters[name]
    return persister if persister

    persister_class = @@persister_kinds[kind]
    return nil unless persister_class

    persister = persister_class.new(name, :xml_format, arg)
    @@known_persisters[name] = persister

    return persister
  end

  def Xampl.find_named_persister(name)
    persister = @@known_persisters[name]
  end

  def Xampl.enable_named_persister(name)
    persister = @@known_persisters[name]
    raise NoPersisterNamed.new(name) unless persister

    @@persister = persister
  end

  def Xampl.enable_persister(name, preferred_kind=nil)
    # you'd better know what you are doing if you call this

    raise NoPersisterNamed.new unless name

    preferred_kind = preferred_kind || Xampl.default_persister_kind

    @@persister = @@known_persisters[name] || Xampl.create_named_persister(name, preferred_kind, nil)
    @@persister
  end

  def Xampl.print_known_persisters
    puts "Known Persisters:: --------------------------"
    @@known_persisters.each { |n, k| puts " #{n} #{k}" }
    puts "---------------------------------------------"
    puts caller(0)
  end

  def Xampl.flush_persister_caches
    Xampl.print_known_persisters
    @@persister.close
    @@known_persisters.delete(@@persister.name)
    Xampl.print_known_persisters
  end

  def Xampl.drop_all_persisters(verbose=false)
    puts "Drop All Persisters:: --------------------------" if verbose
    @@persister = nil
    @@known_persisters.each do |name, persister|
      puts " #{ name } #{ persister.class.name }" if verbose
      next if persister == @@persister
      persister.close
      persister.clear_cache
    end
    @@known_persisters = {}
    puts "---------------------------------------------" if verbose
    GC.start
    GC.start
    GC.start
  end

  def Xampl.drop_persister(name)
#    Xampl.print_known_persisters
    p = @@known_persisters[name]
    p.close if p
    @@known_persisters.delete(name)
#    Xampl.print_known_persisters
  end

  def Xampl.add_lexical_indexs(indexes)
    case Xampl.default_persister_kind
      when :tokyo_cabinet then
        Xampl::TokyoCabinetPersister.add_lexical_indexs(indexes)
      when :redis then
        Xampl::RedisPersister.add_lexical_indexs(indexes)
      #when :mongo then
      #  Xampl::MongoPersister.add_lexical_indexs(indexes)
      else
        raise IncompatiblePersisterConfiguration.new(Xampl.default_persister_kind, "lexical_indexes")
    end
  end

  def Xampl.add_numerical_indexs(indexes)
    case Xampl.default_persister_kind
      when :tokyo_cabinet then
        Xampl::TokyoCabinetPersister.add_numerical_indexs(indexes)
      when :redis then
        Xampl::RedisPersister.add_numerical_indexs(indexes)
      #when :mongo then
      #  Xampl::MongoPersister.add_numerical_indexs(indexes)
      else
        raise IncompatiblePersisterConfiguration.new(Xampl.default_persister_kind, "numerical_indexs")
    end
  end

  @@xampl_lock = Sync.new

  @@verbose_transactions = true

  def Xampl.verboseTransactions(v)
    @@verbose_transactions = v
  end

  class TransactionWork
    def self.setup_work(work)
      begin
        define_method(:do_work, work)
        self.new.do_work
      ensure
        remove_method(:do_work)
      end
    end
  end

  @@abnormal_return_from_transactions_are_errors = true

  def Xampl.abnormal_return_from_transactions_are_errors
    @@abnormal_return_from_transactions_are_errors
  end

  def Xampl.abnormal_return_from_transactions_are_errors=(v)
    @@abnormal_return_from_transactions_are_errors = v
  end

  def Xampl.transaction_as_a_method(thing, kind=nil, automatic=true, format=nil, & block)
    #TODO -- should this be called Xampl.transaction_safe???
    #TODO -- won't work in xampl-gen
    return nil unless block_given?

    if String === thing then
      name = thing
    elsif XamplObject === thing then
      name = thing.persister.name
    else
      raise XamplException.new("can't base a transaction on a #{thing.class.name} (#{thing})")
    end

    work = Proc.new # get the block into a proc object

    @@xampl_lock.synchronize(:EX) do
      begin
        initial_persister = @@persister
        Xampl.enable_persister(name, kind)

        original_automatic = @@persister.automatic

        okay = false
        rollback = true
        exception = nil
        abnormal_return = true
        result = nil

        begin
          #TODO -- impose some rules on nested transactions/enable_persisters??

          Xampl.auto_persistence(automatic)

          result = TransactionWork.setup_work(work)

          abnormal_return = false

          Xampl.block_future_changes(true)
          Xampl.sync
          rollback = false

          okay = true
          return result
        rescue => e
          exception = e
        ensure
          Xampl.block_future_changes(false)
          Xampl.auto_persistence(original_automatic)

          unless okay then
            if exception then
              Xampl.rollback
            elsif abnormal_return then
              if Xampl.abnormal_return_from_transactions_are_errors then
                Xampl.rollback
                exception = UnexpectedExitFromTransaction.new
              else
                begin
                  Xampl.block_future_changes(true)
                  Xampl.sync
                rescue => e
                  exception = e
                ensure
                  Xampl.block_future_changes(false)
                  Xampl.auto_persistence(original_automatic)

                  Xampl.rollback if exception
                end
              end
            elsif rollback then
              # don't know how this can happen, but roll it back anyway and treat it as an unexpected exit from transaction
              Xampl.rollback
              exception =  UnexpectedExitFromTransaction.new
            end
          end

          @@persister = initial_persister
          raise exception if exception
        end
      end
    end
  end

  def Xampl.transaction(thing, kind=nil, automatic=true, format=nil, & block)
    # this method cannot account for returns in transactions (proc vs lambda/method issues)
    if String === thing then
      name = thing
    elsif XamplObject === thing then
      name = thing.persister.name
    else
      raise XamplException.new("can't base a transaction on a #{thing.class.name} (#{thing})")
    end

    if block_given? then
      @@xampl_lock.synchronize(:EX) do
        rollback = true
        exception = nil
        begin
          initial_persister = @@persister
          Xampl.enable_persister(name, kind)

          original_automatic = @@persister.automatic

          begin
            #TODO -- impose some rules on nested transactions/enable_persisters??

            Xampl.auto_persistence(automatic)

            result = yield

            rollback = false
            Xampl.block_future_changes(true)
            Xampl.sync
            return result
          rescue => e
#            puts e.backtrace
            exception = e
          ensure
            Xampl.block_future_changes(false)
            Xampl.auto_persistence(original_automatic)

            if rollback then
              # we get here if the transaction block finishes early, for one of three reasons:
              #    1) exception
              #    2) throw
              #    3) explicit return in the block
              # it is arguable that throw and returns are 'okay', or normal exits from the block... I don't know???

              if exception then
                # the early finish was caused by an exception

                Xampl.rollback
              else
                # this is the throw/explicit-return

                #TODO -- is this a good idea??
                Xampl.block_future_changes(true)
                Xampl.sync


                #TODO -- uncomment this, it's handy
#                STDERR.puts "---------"
#                STDERR.puts "Either a return or a throw from a transaction. The DB is synced, but this is not a good thing to be doing."
#                STDERR.puts caller(0)
#                STDERR.puts "---------"
              end
            end
          end
        ensure
          @@persister = initial_persister

          if exception then
            raise RuntimeError, "ROLLBACK(#{__LINE__}):: #{exception}", exception.backtrace
          end
        end
      end
    end
  end

  def Xampl.transaction_not_so_good(thing, kind=nil, automatic=true, format=nil, & block)
    # this method cannot account for returns in transactions (proc vs lambda/method issues)
    if String === thing then
      name = thing
    elsif XamplObject === thing then
      name = thing.persister.name
    else
      raise XamplException.new("can't base a transaction on a #{thing.class.name} (#{thing})")
    end

    if block_given? then
      @@xampl_lock.synchronize(:EX) do
#      if true then
        begin
#          @@xampl_lock.sync_lock(:EX)
          initial_persister = @@persister
          Xampl.enable_persister(name, kind)

          rollback = true
          exception = nil
          original_automatic = @@persister.automatic

          begin
            #TODO -- impose some rules on nested transactions/enable_persisters??

            Xampl.auto_persistence(automatic)

            result = yield

            rollback = false
            Xampl.block_future_changes(true)
            Xampl.sync
            return result
          rescue => e
            puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] TEST ME"
            puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] rollback: #{ rollback }"
            exception = e
          ensure
            Xampl.block_future_changes(false)
            Xampl.auto_persistence(original_automatic)

            puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] rollback: #{ rollback }"
            if rollback then
              puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] TEST ME"
              puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] rollback: #{ rollback }"
              # we get here if the transaction block finishes early
              if exception then
                puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] rollback: #{ rollback }"
                # the early finish was caused by an exception
                raise RuntimeError, "ROLLBACK(#{__LINE__}):: #{exception}", exception.backtrace
              else
                puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] TEST ME"
                # How could we have arrived at this point???
                # Well, I don't know all the reasons, but the ones I do know are:
                #  - return was used in the block passed into the transaction
                #  - a throw was made
                # There's no way that I know of to distinguish, so, assume that the transaction worked
                #    20091202 -- well maybe not...

#                Xampl.rollback # this is bad
                rollback = true
#                raise  ReturnOrThrowInTransaction
                STDERR.puts "---------"
                STDERR.puts "Either a return or a throw from a transaction. The DB is possibly not synced."
                caller(0).each do |trace|
                  STDERR.puts(trace)
                end
                STDERR.puts "---------"
              end
            else
              puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] TEST ME"
            end

            if rollback then
              puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] TEST ME"
              Xampl.rollback
              rollback = false
            else
              puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] TEST ME"
            end
            @@persister = initial_persister
          end
          puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] rollback: #{ rollback }"
          if exception
            puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] rollback: #{ rollback }"
            raise exception
          else
            puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] rollback: #{ rollback }"
          end
        ensure
          puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] TEST ME" if rollback
          puts "#{File.basename(__FILE__)}:#{__LINE__} [#{ __method__ }] rollback: #{ rollback } ????????????" if rollback
#          @@xampl_lock.sync_unlock
        end
      end
    end
  end

  def Xampl.read_only_transaction(thing, kind=nil, automatic=true, format=nil, & block)
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
        Xampl.enable_persister(name, kind)
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

            #if exception then
            #  puts "ROLLBACK(#{__LINE__}):: #{exception}"
            #  print exception.backtrace.join("\n") if exception
            #end

            #no change so don't bother with rollback
#            if rollback then
#              Xampl.rollback
#            end
            @@persister = initial_persister
          else
            #puts "CHANGED COUNT: #{@changed.size}"
            @changed = original_changed

            #puts "ROLLBACK(#{__LINE__}) #{exception}" if rollback
            #print exception.backtrace.join("\n")
            Xampl.rollback

            @@persister = initial_persister

            raise BlockedChange.new(target_persister)
          end
        end
      end
    end
  end

  def Xampl.read_only(target_persister)
    @@xampl_lock.synchronize(:EX) do
      name = target_persister.name

      if block_given? then
        initial_persister = @@persister
        Xampl.enable_persister(name, target_persister.kind)

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

            #puts "ROLLBACK(#{__LINE__})" if rollback
            Xampl.rollback if rollback
            @@persister = initial_persister
          else
            #puts "CHANGED COUNT: #{@changed.size}"
            @changed = original_changed

            #puts "ROLLBACK(#{__LINE__})" if rollback
            Xampl.rollback

            @@persister = initial_persister

            raise BlockedChange.new(target_persister)
          end
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

  def Xampl.sync_all
    @@known_persisters.each { |name, persister| persister.sync }
  end

  def Xampl.close_all_persisters
    @@known_persisters.each do |name, persister|
      persister.close
    end
  end

  def Xampl.rollback(persister=@@persister)
    raise NoActivePersister unless @@persister
    persister.rollback_cleanup
  end

  def Xampl.rollback_all
    @@known_persisters.values.each { |persister| persister.rollback }
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

  def Xampl.query_implemented
    raise NoActivePersister unless @@persister
    @@persister.query_implemented
  end

  def Xampl.query(hint=false)
    raise NoActivePersister unless @@persister
    @@persister.query(hint) { |q| yield q }
  end

  def Xampl.find_xampl(hint=false)
    raise NoActivePersister unless @@persister
    @@persister.find_xampl(hint) { |q| yield q }
  end

  def Xampl.find_meta(hint=false)
    raise NoActivePersister unless @@persister
    @@persister.find_meta(hint) { |q| yield q }
  end

  def Xampl.find_pids(hint=false)
    raise NoActivePersister unless @@persister
    @@persister.find_pids(hint) { |q| yield q }
  end

  def Xampl.find_mentions_of(xampl)
    raise NoActivePersister unless @@persister
    @@persister.find_mentions_of(xampl)
  end

end

