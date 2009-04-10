#!/usr/bin/env ruby

require "xampl"
include Xampl

require "tmp/XamplExample"
include XamplExample

require "benchmark"
include Benchmark

#
# results from 16 October 2005
#

#Rebuilding From String (YAML & XML) count: 1000 (est. ~ 11s)
#                user     system      total        real
#yaml        2.590000   0.050000   2.640000 (  3.180061)
#xml         5.970000   0.080000   6.050000 (  6.573804)
#ruby        1.660000   0.030000   1.690000 (  2.017015)

#Serialize to String (YAML & XML) count: 1000 (est. ~ 25s)
#                user     system      total        real
#yaml       14.360000   0.250000  14.610000 ( 16.128599)
#xml         1.460000   0.020000   1.480000 (  1.576753)
#ruby        0.890000   0.010000   0.900000 (  1.102071)

#Round Tripping (YAML & XML) count: 1000 (est. ~ 40s)
#                user     system      total        real
#yaml       17.420000   0.270000  17.690000 ( 19.390348)
#xml         7.890000   0.110000   8.000000 (  8.860720)
#ruby        2.780000   0.040000   2.820000 (  3.131707)

module Bench

  def Bench.go
    count = 1000

    emph_content_1 = "there"
    emph1 = Emph.new
    emph1 << emph_content_1

    emph_content_2 = "are"
    emph2 = Emph.new
    emph2.content = emph_content_2

    desc1 = Description.new
    desc1.kind = "desc1"

    desc1.is_changed = nil
    desc1 << "hello " << emph1 << "! How " << emph2 << " you?"

    thing = Thing.new
    thing.pid = "thing"
    thing.new_stuff.kind = "stuff1"
    thing << desc1

    big_thing = Thing.new
    big_thing << thing

    #require "to-ruby"
    #ruby_printer = RubyPrinter.new
    #ruby_s = ruby_printer.to_ruby(thing)
    ruby_s = thing.to_ruby
    yaml_s = thing.as_yaml
    xml_s = thing.persist

    #puts yaml_s
    puts xml_s
    puts ruby_s
    puts "++++++++++++++++++++++++++++++++++++"
    puts "big_thing #{big_thing.object_id}, thing #{thing.object_id}"
    puts big_thing.to_ruby
    puts "++++++++++++++++++++++++++++++++++++"

    puts "Rebuilding From String (YAML & XML) count: #{count} (est. ~ 11s)"
    bm(10) do | x |
      x.report("yaml") {
        count.times {
          something = XamplObject.from_yaml(yaml_s)
        }
      }
      x.report("xml") {
        count.times {
          another_big_thing = XamplObject.from_xml_string(xml_s)
        }
      }
      x.report("ruby") {
        count.times {
          XamplObject.from_ruby(ruby_s)
        }
      }
    end

    puts "Serialize to String (YAML & XML) count: #{count} (est. ~ 25s)"
    bm(10) do | x |
      x.report("yaml") {
        count.times {
          yaml_s = thing.as_yaml
        }
      }
      x.report("xml") {
        count.times {
          xml_s = thing.persist
        }
      }
      x.report("ruby") {
        count.times {
          ruby_s = thing.to_ruby
        }
      }
    end

    puts "Round Tripping (YAML & XML) count: #{count} (est. ~ 40s)"
    bm(10) do | x |
      x.report("yaml") {
        count.times {
          something = XamplObject.from_yaml(thing.as_yaml)
        }
      }
      x.report("xml") {
        count.times {
          another_thing = XamplObject.from_xml_string(thing.persist)
        }
      }
      x.report("ruby") {
        count.times {
          XamplObject.from_ruby(thing.to_ruby)
        }
      }
    end
  end
end

Bench.go

