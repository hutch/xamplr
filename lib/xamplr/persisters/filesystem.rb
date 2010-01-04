module Xampl

  require "fileutils"
  require "xamplr/persisters/caching"

  class FilesystemPersister < AbstractCachingPersister

    def initialize(name=nil, format=nil, root=File.join(".", "repo"))
      super(root, name, format)
    end

    def FilesystemPersister.kind
      :filesystem
    end

    def kind
      FilesystemPersister.kind
    end

    def write(xampl)
      #raise XamplException.new(:no_index_so_no_persist) unless xampl.get_the_index or xampl.ignore_when_no_index
      raise XamplException.new("no_index_so_no_persist [#{xampl.class.name}]") unless xampl.get_the_index or xampl.ignore_when_no_index
      return unless xampl.get_the_index

      place = File.join(@root_dir, xampl.class.name.split("::"))

      FileUtils.mkdir_p(place) unless File.exist?(place)

      place = File.join(place, xampl.get_the_index)

      representation = represent(xampl)
      if representation then
        File.open(place, "w")do |out|
          out.puts representation
          out.fsync
          if $is_darwin then
            out.fcntl(51, 0) # Attempt an F_FULLFSYNC fcntl to commit data to disk
          end

        end
        @write_count = @write_count + 1
      end
      xampl.changes_accepted
      return true
    end

    def read_representation(klass, pid)
      place = File.join(@root_dir, klass.name.split("::"), pid)

      return nil unless File.exist?(place)
      representation = File.read(place)
      return representation
    end
  end

  Xampl.register_persister_kind(FilesystemPersister)
end

