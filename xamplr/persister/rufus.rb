
# This doesn't work so well. This will be removed soon.

module Xampl

  require "fileutils"
  require 'rufus/tokyo'
  require "persister/caching"

  class TokyoCabinetPersister < AbstractCachingPersister

    def initialize(name=nil, format=nil, root=File.join(".", "repo"))
      super(root, name, format)

      FileUtils.mkdir_p(@root_dir) unless File.exist?(@root_dir)
      @tc_db = Rufus::Tokyo::Table.new("#{@root_dir}/repo.tct", :mode => 'wc', :opts => 'ld', :mutex => true)
    end

    def TokyoCabinetPersister.kind
      :tokyo_cabinet
    end

    def kind
      TokyoCabinetPersister.kind
    end

    def rollback_cleanup
      super
      # @db.clear_cache -- TODO is something like this needed with TC?
    end

    def do_sync_write
      @time_stamp = Time.now.to_f.to_s

      @tc_db.transaction do
        @changed.each { | xampl, ignore | write(xampl) }
      end
    end

    def query
      results = @tc_db.query do | q |
        yield q
      end
      # p results

      class_cache = {}
      results.each do | result |
        class_name = result['class']
        result_class = class_cache[class_name]
        unless result_class then
          class_name.split("::").each do | chunk |
            if result_class then
              result_class = result_class.const_get( chunk )
            else
              result_class = Kernel.const_get( chunk )
            end
          end

          class_cache[class_name] = result_class
        end

        result_pid = result['pid']

        x = self.lookup(result_class, result['pid'])
        result['xampl'] = x if x
      end

      results
    end

    def write(xampl)
      raise XamplException.new(:no_index_so_no_persist) unless xampl.get_the_index

      place = File.join(xampl.class.name.split("::"), xampl.get_the_index)

      data = represent(xampl)

      xampl_hash = {
              'class' => xampl.class.name,
              'pid' => xampl.get_the_index,
              'time-stamp' => @time_stamp,
              'xampl' => data
      }

      hash = xampl.describe_yourself
      if hash then
        xampl_hash = hash.merge(xampl_hash)
      end

      @tc_db[place] = xampl_hash

      @write_count = @write_count + 1
      xampl.changes_accepted
      return true
    end

    def read_representation(klass, pid)
      # place = place_name(klass, pid)
      place = File.join(klass.name.split("::"), pid)
      representation = nil
      @tc_db.transaction do
        representation = @tc_db[place]['xampl']
      end

      # puts "read: #{ place }, size: #{ representation.size }"
      # puts representation[0..100]

      return representation
    end
  end

  Xampl.register_persister_kind(TokyoCabinetPersister)
end

