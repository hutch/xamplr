module Xampl
  class Version
    @@version_limit = 5

    def initialize(repo_name, repo_root)
      @invalid = true
      throw :refuse_to_version unless repo_name

      repo_name.gsub!(/^[\.\/]*/, '')
      repo_name.gsub!(/\/.*/, '')
      throw :refuse_to_version unless repo_name

      @repo_root = repo_root
      @repo_root << '/' unless '/'[-1] == @repo_root[-1]

      @repo_path = "#{@repo_root}#{repo_name}"
      @repo_name = repo_name

      throw :refuse_to_version if @repo_path == @repo_root
      throw :refuse_to_version unless File.directory?(@repo_path)

      @invalid = false
    end

    def make(version_stream, description=nil)
      throw :refuse_to_version if @invalid

      existing_versions = Dir.glob("#{@repo_root}/#{@repo_name}_#{version_stream}*")

      if 0 == existing_versions.size then
        make_first_version(version_stream, existing_versions, description)
      else
        make_new_version(version_stream, existing_versions, description)
      end
    end

    def make_first_version(version_stream, existing_versions, description)
      cmd = "cd '#{@repo_root}'; rsync -a --delete '#{@repo_name}/'  '#{@repo_name}_#{version_stream}.0/'"
      # puts "first version: #{cmd}"
      system(cmd)
    end

    def make_new_version(version_stream, existing_versions, description)

      existing_versions.reverse!
      cmd = []
      eliminate = []
      existing_versions.each_with_index do | version, i |
        pushed_name = "#{@repo_name}_#{version_stream}.#{i + 1}"
        cmd << "mv '#{@repo_name}_#{version_stream}.#{i}' '#{pushed_name}'"
        eliminate << pushed_name unless i < @@version_limit
      end
      cmd << "cd '#{@repo_root}'"
      cmd = cmd.reverse
      cmd << "rsync -a --delete --checksum --link-dest='../#{@repo_name}_#{version_stream}.1' '#{@repo_name}/'  '#{@repo_name}_#{version_stream}.0/'"
      cmd << "touch '#{@repo_name}_#{version_stream}.0'"

      eliminate.each do | name |
        cmd << "rm -rf '#{name}'"
      end

      cmd = cmd.join("; ")
      # puts "new version: #{cmd}"
      system(cmd)
    end
  end
end
