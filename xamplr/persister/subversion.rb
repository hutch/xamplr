module Xampl

  require 'version'

  require "fileutils"
  require "persister/caching"

  class SubversionPersister < AbstractCachingPersister

    def initialize(name=nil, format=nil, root=File.join(".", "repo"))
      super(root, name, format)
    end

    def SubversionPersister.kind
      :subversion
    end

    def kind
      SubversionPersister.kind
    end

    def version(stream)
      catch(:refuse_to_version) do
        Version.new(@repo_name, @repo_root).make(stream)
      end
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
        File.open(place, "w"){ | out |
          out.puts representation
        }
        @write_count = @write_count + 1
      end
      xampl.changes_accepted
      return true
    end

    def read_representation(klass, pid)
      place = File.join(@root_dir, klass.name.split("::"), pid)

      return nil unless File.exist?(place)
      return File.read(place)
    end
  end

  Xampl.register_persister_kind(SubversionPersister)
end

