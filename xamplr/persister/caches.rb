
module Xampl

  #TODO -- this is **way** too big!
  #TODO -- FIX THIS PROBLEM
#  increase the default cache size to 2000 (which is way too big, but there is
#  a bug... removing from the cache does not remove from memory, so if a
#  storybook exists that points (even indirectly) at something flushed, the
#  thing flushed is still held in memory. What is needed is for the thing to
#  be invalidated somehow withought DUPLICATES being created when the thing
#  is read again next time)

  DEFAULT_CAPACITY = 2000

  class XamplCache
	  require 'indexed-array'

		attr_reader :cache, :capacity

	  def initialize(capacity=DEFAULT_CAPACITY)
			@capacity = capacity
			@now = 0
      @size = 0
			@cache = {}
		end

		def size
      #@cache.size
      return @size
		end

    def delete(key)
		  @cache.delete(key)
    end

		def limit
			victim = nil
      actual_victim = nil
			min = 1 + @now
      @size = 0
			@cache.each{ | key, pair |
			  possibility = pair[0]
				if (not possibility.load_needed) and pair[1] < min then
          @size += 1
			    victim = key
          actual_victim = possibility
					min = pair[1]
				end
			}
#puts
#puts
#puts "REMOVE FROM CACHE(XamplCache): victim: #{victim}, actual: #{actual_victim}"
#puts " size: #{@size}, physical size: #{@cache.size}"
#puts
#puts
      #@cache.delete(victim)
      actual_victim.force_load if actual_victim
#puts ">>>>>>> #{actual_victim.load_needed} #{actual_victim.class.name}" if actual_victim
		end

    def fetch(key, default_value=nil)
			pair = @cache[key]
			if pair then
			  pair[1] = (@now += 1)
				return pair[0]
			else
        return default_value
			end
    end

    def store(key, value)
		  if(@capacity <= @size) then
			  self.limit
			end

			pair = @cache[key]
			if pair then
			  pair[0] = value
				pair[1] = (@now += 1)
			else
			  @cache[key] = [value, (@now += 1)]
			end

      return value
    end

		def print(out = "")
		  out << "Cache with capacity: #{@capacity}, current size: #{@size}\n"
			@cache.each{ | key, pair | 
			   out << sprintf("  key: '%s', value: '%s', accessed: %s\n",
				                key, pair[0], pair[1])
			}
			out
		end
  
    alias [] fetch
    alias []= store
	end

  class XamplCacheLFU
	  require 'indexed-array'

		attr_reader :cache, :capacity

	  def initialize(capacity=DEFAULT_CAPACITY)
			@capacity = capacity
			@accesses = 0
      @size = 0
			@cache = {}
		end

		def size
      #@cache.size
      @size
		end

    def delete(key)
		  @cache.delete(key)
    end

		def limit
			victim = nil
			actual_victim = nil
			min = 1 + @accesses
      live = 0
			@cache.each{ | key, pair |
				pair[1] -= 1
        possibility = pair[0]
				if (not possibility.load_needed) and pair[1] < min then
          live += 1
			    victim = key
          actual_victim = possibility
					min = pair[1]
				end
			}
#puts
#puts
#puts "REMOVE FROM CACHE(XamplCacheLFU): victim: #{victim}, actual: #{actual_victim} -- live: #{live}, size: #{@size}"
#puts
#puts
      #@cache.delete(victim)
      actual_victim.force_load if actual_victim
		end

    def fetch(key, default_value=nil)
		  @accesses += 1

			pair = @cache[key]
			if pair then
			  pair[1] += 1
				return pair[0]
			else
        return default_value
			end
    end

    def store(key, value)
		  @accesses += 1

		  if(@capacity <= @size) then
			  self.limit
			end

			pair = @cache[key]
			if pair then
			  pair[0] = value
			  pair[1] += 1
			else
			  @cache[key] = [value, 1]
			end

      return value
    end

		def print(out = "")
		  out << "Cache with capacity: #{@capacity}, current size: #{@size}\n"
			@cache.each{ | key, pair | 
			   out << sprintf("  key: '%s', value: '%s', count: %s\n",
				                key, pair[0], pair[1])
			}
			out
		end
  
    alias [] fetch
    alias []= store
	end
end
