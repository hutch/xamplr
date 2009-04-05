#!/usr/bin/env ruby -w -I..

#require 'rubygems'
#require_gem 'xampl-generator'

#$LOAD_PATH.unshift('/Users/hutch/Projects/xampl/play')
#$LOAD_PATH.unshift('/Users/hutch/Projects/agri/xox/xamplr')

$LOAD_PATH.unshift("../../../xamplr-pp")
$LOAD_PATH.unshift("../../xamplr")

class File
  def File.sjoin(*args)
    File.join(args.select{ | o | o })
  end
end

#require 'xampl'
require 'xampl-generator'

include XamplGenerator
include Xampl

Xampl.transaction("setup", :in_memory) do
  directory = File.sjoin(".", "xampl_generated_code")

  options = Xampl.make(Options) { | options |
    options.new_index_attribute("pid").persisted = true
    options.new_index_attribute("id")

    options.resolve("http://xampl.com/tcx", "TokyoCabinetExperimental", "tcx")
  }

  filenames = Dir.glob("./xml/**/*.xml")
  #filenames.concat(Dir.glob("./xml/scenarios/**/*.xml"))

  generator = Generator.new
  generator.go(:options => options,
               :filenames => filenames,
               :directory => directory)

  #puts generator.print_elements("./generated-elements.xml")
  exit!
end

