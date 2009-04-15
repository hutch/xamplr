#!/usr/bin/env ruby

require 'xamplr-generator'
include XamplGenerator
include Xampl

options = Xampl.make(Options) { | options |
  options.new_index_attribute("name")
  options.new_index_attribute("id")
  options.new_index_attribute("pid").persisted = true

  options.resolve("http://xampl.com/generator", "XamplGenerator", "gen")
}

XamplGenerator.from_command_line(options)
