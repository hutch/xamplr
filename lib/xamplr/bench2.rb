#!/usr/bin/env ruby

require "xamplr"
include Xampl

require "tmp/XamplExample"
include XamplExample

require "benchmark"
include Benchmark

require 'persister/fsdb'

module Bench

  def Bench.go
    count_things = 1000
    count = 10

    puts "NO ROLLBACKS..."
    writes = 0
    bm(10) do | x |
      x.report("simple") {
        Xampl.enable_persister("bench2_no_rollback_simple", :simple)
        Bench.no_rollbacks(count_things, count)
      }
      x.report("in_memory") {
        Xampl.enable_persister("bench2_no_rollback_in_memory", :in_memory)
        Bench.no_rollbacks(count_things, count)
      }
      x.report("filesystem") {
        Xampl.enable_persister("bench2_no_rollback_filesystem", :filesystem)
        writes += Bench.no_rollbacks(count_things, count)
      }
      x.report("fsdb") {
        Xampl.enable_persister("bench2_no_rollback_fsdb", :fsdb)
        Bench.no_rollbacks(count_things, count)
      }
    end
    puts "   writes: #{writes}"

    writes = 0
    puts "WITH ROLLBACKS..."
    bm(10) do | x |
      x.report("simple") {
        Xampl.enable_persister("bench2_rollback_simple", :simple)
        Bench.rollbacks(count_things, count)
      }
      x.report("in_memory") {
        Xampl.enable_persister("bench2_rollback_in_memory", :in_memory)
        Bench.rollbacks(count_things, count)
      }
      x.report("filesystem") {
        Xampl.enable_persister("bench2_rollback_filesystem", :filesystem)
        writes += Bench.rollbacks(count_things, count)
      }
      x.report("fsdb") {
        Xampl.enable_persister("bench2_rollback_fsdb", :fsdb)
        Bench.rollbacks(count_things, count)
      }
    end
    puts "   writes: #{writes}"
  end

  def Bench.no_rollbacks(count_things, count)
    writes = 0
    things = []
    count_things.times { | i |
      thing = Bench.make_a_thing("thing-#{i}")
      Xampl.introduce_to_persister(thing)
      things << thing
    }

    things.each{ | thing | Xampl.introduce_to_persister(thing) }
    count.times { | time |
      things.each{ | thing |
        thing.info = [thing.pid, time].join
      }
      writes += Xampl.sync
    }
    return writes
  end

  def Bench.rollbacks(count_things, count)
    writes = 0
    things = []
    count_things.times { | i |
      thing = Bench.make_a_thing("thing-#{i}")
      Xampl.introduce_to_persister(thing)
      things << thing
    }

    things.each{ | thing | Xampl.introduce_to_persister(thing) }
    count.times { | time |
      writes += Xampl.sync
      Xampl.rollback

      things.each{ | thing |
        thing.info = [thing.pid, time].join
      }
    }
    return writes
  end

  def Bench.make_a_thing(pid)
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
    thing.pid = pid
    thing.info = pid
    thing.new_stuff.kind = "stuff1"
    thing << desc1

    return thing
  end

end

Bench.go

