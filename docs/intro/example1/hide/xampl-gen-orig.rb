#!/usr/bin/env ruby -w -I..

if $0 == __FILE__ then

  class File
    def File.sjoin(*args)
      File.join(args.select{ | o | o })
    end
  end

  $LOAD_PATH.unshift('../../../lib/')

  require 'xamplr-generator'

  include XamplGenerator
  include Xampl

  Xampl.transaction("setup") do
    directory = File.sjoin(".", "xampl_generated_code")

    options = Xampl.make(Options) do | opts |
      opts.new_index_attribute("pid").persisted = true
      opts.new_index_attribute("id")

      #opts.resolve("http://xampl.com/people", "RandomPeople", "p")
    end

    filenames = Dir.glob("./xml/**/*.xml")

    generator = Generator.new('generator')
    generator.go(:options => options,
                 :filenames => filenames,
                 :directory => directory)

    puts generator.print_elements("./generated-elements.xml")
  end
end
