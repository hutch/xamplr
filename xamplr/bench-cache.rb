#!/usr/bin/env ruby

require "xampl"
include Xampl

require "tmp/XamplExample"
include XamplExample

require "benchmark"
include Benchmark

require 'persister/fsdb'
require 'wee-cache/cache'

class LRUCache < Cache::StorageCache
  def initialize(capacity=20)
    super(Cache::Strategy::LRU.new(capacity))
  end 
end   

class LRU2Cache < Cache::StorageCache
  def initialize(capacity=20)
    super(Cache::Strategy::LRU2.new(capacity))
  end 
end   

class LFUCache < Cache::StorageCache
  def initialize(capacity=20)
    super(Cache::Strategy::LFU.new(capacity))
  end 
end   


module Bench

  def Bench.go
    count = 1000
		capacity = 500

    bm(15) do | x |
      x.report("XamplCache") {
	      cache = XamplCache.new(capacity)

		    count.times { | i |
			    cache[i] = i
		    }
      }
      x.report("XamplCacheLFU") {
	      cache = XamplCacheLFU.new(capacity)

		    count.times { | i |
			    cache[i] = i
		    }
      }
      x.report("LRU") {
	      cache = LRUCache.new(capacity)

		    count.times { | i |
			    cache[i] = i
		    }
      }
      x.report("LRU2") {
	      cache = LRU2Cache.new(capacity)

		    count.times { | i |
			    cache[i] = i
		    }
      }
      x.report("LFU") {
	      cache = LFUCache.new(capacity)

		    count.times { | i |
			    cache[i] = i
		    }
      }
    end
  end
end

Bench.go
