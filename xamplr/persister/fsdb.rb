module Xampl

  require "fileutils"
  require "fsdb"
  require "persister/caching"

  class FSDBPersister < AbstractCachingPersister

    def initialize(name=nil, format=nil, root=File.join(".", "repo-fsdb"))
      super(root, name, format)

      @db = FSDB::Database[@root_dir]
      @db_lock = "lock"
      @db[@db_lock] = @db_lock
    end

    def FSDBPersister.kind
      :fsdb
    end

    def kind
      FSDBPersister.kind
    end

    def rollback_cleanup
      super
      @db.clear_cache
    end

    def do_sync_write
      @db.edit(@db_lock){ | lock |
        @changed.each { | xampl, ignore | write(xampl) }
      }
    end

    def place_name(klass, id, type=".txt")
      place = File.join(klass.name.split("::"), "#{id}#{type}")
      return place
    end

    def write(xampl)
      raise XamplException.new(:no_index_so_no_persist) unless xampl.get_the_index
      #return false unless xampl.get_the_index

      place = place_name(xampl.class, xampl.get_the_index)
      @db[place] = represent(xampl)

      @write_count = @write_count + 1
      xampl.changes_accepted
      return true
    end

    def read_representation(klass, pid)
      place = place_name(klass, pid)
      representation = @db.edit(@db_lock){ | lock | @db[place] }
      return representation
    end
  end

  Xampl.register_persister_kind(FSDBPersister)
end

