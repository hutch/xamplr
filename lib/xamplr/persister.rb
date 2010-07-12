require "xamplr/persistence"

require 'set'

module Xampl
  class Persister
    attr_accessor :name,
                  :automatic,
                  :block_changes,
                  :read_count, :total_read_count,
                  :write_count, :total_write_count,
                  :total_sync_count, :total_rollback_count,
                  :cache_hits, :total_cache_hits,
                  :last_write_count,
                  :rolled_back,
                  :expunged,
                  :slow_sync
    attr_reader :syncing, :format

    def initialize(name=nil, format=nil)
      @name = name
      @format = format
      @automatic = false
      @changed = {}
      @expunged = Set.new
      @cache_hits = 0
      @total_cache_hits = 0
      @read_count = 0
      @total_read_count = 0
      @write_count = 0
      @total_write_count = 0
      @last_write_count = 0
      @last_cache_hits = 0
      @total_sync_count = 0
      @total_rollback_count = 0
      @rolled_back = false
      @syncing = false
      @slow_sync = 0.25

      @busy_count = 0
    end

    def optimise(opts)
    end

    def close
      self.sync
    end

    def shutdown
#      self.sync
#      self.close
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

    def represent(xampl, mentions=[])
      #puts "REPRESENT #{xampl} load needed: #{xampl.load_needed}"
      #      return nil if xampl.load_needed
      rep = nil
      case xampl.default_persister_format || @format
        when nil, :xml_format then
          rep = xampl.persist("", mentions)
        when :ruby_format then
          rep = xampl.to_ruby(mentions)
      end
      return rep
    rescue => e
      msg = "Failed to represent #{ xampl } due to: #{ e }"
      puts msg
      puts e.backtrace
      raise msg
    end

    def realise(representation, target=nil)
      # Normally we'd expect to see the representation in the @format format, but
      # that isn't necessarily the case. Try to work out what the format might be...

      #TODO -- this is a bit brutal, but it should work (it is the rule is that this is supposed to be UTF-8)
      representation_fixed = representation.encode('UTF-8', :invalid => :replace, :undef => :replace)
#      puts "#{ ::File.basename __FILE__ }:#{ __LINE__ } [#{__method__}] ENCODING: #{ representation.encoding } -> #{ representation_fixed.encoding }"

      xampl = nil
      if representation_fixed =~ /^</ then
        xampl = XamplObject.realise_from_xml_string(representation_fixed, target)
      else
        xampl = XamplObject.from_ruby(representation_fixed, target)
      end
      return xampl.note_realised
    end

    def write(xampl)
      raise XamplException.new(:unimplemented)
    end

    def read(klass, pid, target=nil)
      raise XamplException.new(:unimplemented)
    end

    def query_implemented
      false
    end

    def find_xampl(hint=false)
      if hint then
        return [], "no query made"
      else
        return []
      end
    end

    def expunge(xampl)
      false
    end

    def lookup(klass, pid)
      #raise XamplException.new(:live_across_rollback) if @rolled_back
      #puts "#{File.basename(__FILE__)} #{__LINE__} LOOKUP:: klass: #{klass} pid: #{pid}"

      begin
        busy(true)
        xampl = read(klass, pid)
      ensure
        busy(false)
      end

      #puts "#{File.basename(__FILE__)} #{__LINE__}       ---> #{ xampl }"

      return xampl
    end

    def find_known(klass, pid)
      #raise XamplException.new(:live_across_rollback) if @rolled_back

      xampl = read_from_cache(klass, pid, nil)

      return xampl
    end

    def lazy_load(target, klass, pid)
      #      puts "#{File.basename(__FILE__)} #{__LINE__} LAZY_LOAD:: klass: #{klass} pid: #{pid} target: #{target}"

      xampl = read(klass, pid, target)

      # puts "   LAZY_LOAD --> #{xampl}"

      return xampl
    end

    def put_changed(msg="")
      puts "Changed::#{msg}:"
      @changed.each { |xampl, ignore| puts " #{xampl.tag} #{xampl.get_the_index}" }
    end

    def start_sync_write
      #only if needed
    end

    def done_sync_write
      # only if needed
    end

    def do_sync_write
      unchanged_in_changed_list = 0
      @changed.each do |xampl, ignore|
        unchanged_in_changed_list += 1 unless xampl.is_changed
        unless xampl.kind_of?(InvalidXampl) then
          write(xampl)
        end
      end
    end

    def sync
      @last_sync_time = Time.now
      #raise XamplException.new(:live_across_rollback) if @rolled_back
      begin
        if 0 < @changed.size then
#          puts "#{ __FILE__ }:#{ __LINE__ } [#{__method__}] SYNC changed: #{@changed.size}"
#          @changed.each do | key, value |
#            puts "    key: #{key.class.name}, pid: #{key.get_the_index}"
#          end

#          caller(0).each do | trace |
#            next if /xamplr/ =~ trace
#            puts " #{trace}"
#            break if /actionpack/ =~ trace
#          end

          duration = Time.now
          begin
            busy(true)
            @syncing = true

            start_sync_write
            do_sync_write
          ensure
            done_sync_write
            @syncing = false
          end

          duration = Time.now - duration
          if @slow_sync < duration.to_f then
            puts "#{ __FILE__ }:#{ __LINE__ } [#{__method__}] SLOW SYNC(#{ duration.to_f }s), changed: #{ @changed.size }"
            @changed.each do |key, value|
              puts "    key: #{ key.class.name }, pid: #{ key.get_the_index }"
            end
          end
        end

        @changed = {}

        puts "SOME NOT EXPUNGED: #{ @expunged.inspect }" unless 0 == @expunged.size
        @expunged = Set.new

        @total_read_count += @read_count
        @total_write_count += @write_count
        @total_cache_hits += @cache_hits
        @total_sync_count += 1

        @last_cache_hits = @cache_hits
        @last_write_count = @write_count
        @cache_hits = 0
        @read_count = 0
        @write_count = 0

        self.sync_done()

        return @last_write_count
      ensure
        busy(false)
#        puts "#{ __FILE__ }:#{ __LINE__ } [#{__method__}] **** SYNCING IS FALSE"
        @syncing = false
        @last_sync_time = Time.now - @last_sync_time
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
      printf("SYNC[%s]:: TOTAL cache_hits: %d, reads: %d, writes: %d\n",
             self.name, @total_cache_hits, @total_read_count, @total_write_count)
      printf("             cache_hits: %d, reads: %d, writes: %d, time: %fms \n",
             @last_cache_hits, @read_count, @last_write_count, @last_sync_time)
      printf("             syncs: %d\n", @total_sync_count)
      if 0 < @changed.size then
        printf("             changed count: %d (%d)\n", count_changed, @changed.size)
        @changed.each do |thing, ignore|
          if thing.is_changed then
            puts "             changed: #{thing}, index: #{thing.get_the_index}"
          else
            puts "             UNCHANGED: #{thing}, index: #{thing.get_the_index} <<<<<<<<<<<<<<<<<<< BAD!"
          end
        end
      end
    end
  end

  require "xamplr/persisters/simple"
  require "xamplr/persisters/dumb"
  require "xamplr/persisters/in-memory"
  require "xamplr/persisters/filesystem"

  begin
    if require 'tokyocabinet' then
      require "xamplr/persisters/tokyo-cabinet"
    end
  rescue LoadError => e
    # Well. No Tokyo Cabinet.
  rescue
    # Well. No Tokyo Cabinet.
  end

  begin
    if require 'mongo' then
      require "xamplr/persisters/mongo"
    end
  rescue LoadError => e
    # Well. No MongoDB.
  rescue
    # Well. No MongoDB.
  end

end
