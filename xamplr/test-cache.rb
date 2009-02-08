#!/usr/bin/env ruby -w

require "test/unit"
require "xampl"

class TestXampl < Test::Unit::TestCase

  def setup
    Xampl.disable_all_persisters
  end

  def test_lose_the_first
	   cache = Xampl::XamplCache.new(10)
		 assert(cache)

     cache['first'] = 'first'
		 assert(cache['first'])

		 10.times { | i |
		   id = "id.#{i}"
			 cache[id] = id
		 }
		 assert_nil(cache['first'])
  end

  def test_lose_the_second
	   cache = Xampl::XamplCache.new(10)
		 assert(cache)

     cache['first'] = 'first'
     cache['second'] = 'second'
		 assert(cache['first'])
		 assert(cache['second'])

		 10.times { | i |
		   id = "id.#{i}"
			 cache[id] = id
		   use_first = cache['first']
		 }
		 assert(cache['first'])
		 assert_nil(cache['second'])
  end

  def test_lose_the_first_XamplCache
	   cache = Xampl::XamplCache.new(10)
		 assert(cache)

		 assert_nil(cache['dummy'])

     cache['dummy'] = 'dummy'
		 assert_equal(1, cache.size)
		 cache.delete('dummy')
		 assert_equal(0, cache.size)
		 assert_nil(cache['dummy'])

     cache['first'] = 'first-value'
		 assert(cache['first'])

		 10.times { | i |
		   key = "thing.#{i}"
		   value = "value.#{i}"
			 cache[key] = value
		 }
		 assert_nil(cache['first'])
  end

  def test_lose_the_second_XamplCache
	   cache = Xampl::XamplCache.new(10)
		 assert(cache)

		 # fill the cache
		 10.times { | i |
		   id = "id.#{i}"
			 cache[id] = id
		   use_first = cache['first']
		 }

     cache['first'] = 'first'
     cache['second'] = 'second'
		 assert(cache['first'])
		 assert(cache['second'])

		 10.times { | i |
		   use_first = cache['first']

		   id = "id.#{10 + i}"
			 cache[id] = id
		 }

		 assert(cache['first'])
		 assert_nil(cache['second'])
  end

  def test_lose_the_first_XamplCacheLFU
	   cache = Xampl::XamplCacheLFU.new(10)
		 assert(cache)

		 assert_nil(cache['dummy'])

     cache['dummy'] = 'dummy'
		 assert_equal(1, cache.size)
		 cache.delete('dummy')
		 assert_equal(0, cache.size)
		 assert_nil(cache['dummy'])

     cache['first'] = 'first-value'
		 assert(cache['first'])
		 cache.delete('first')
		 assert_nil(cache['first'])
     cache['first'] = 'first-value'

		 10.times { | i |
		   key = "thing.#{i}"
		   value = "value.#{i}"
			 cache[key] = value
			 thing = cache[key]
		 }
		 assert_nil(cache['first'])
  end

  def test_lose_the_second_XamplCacheLFU
	   cache = Xampl::XamplCacheLFU.new(10)
		 assert(cache)

		 # fill the cache
		 10.times { | i |
		   id = "id.#{i}"
			 cache[id] = id
		   use_first = cache['first']
		 }

     cache['first'] = 'first'
     cache['second'] = 'second'
		 assert(cache['first'])
		 assert(cache['second'])

		 10.times { | i |
		   use_first = cache['first']

		   id = "id.#{10 + i}"
			 cache[id] = id
		 }

		 assert(cache['first'])
		 assert_nil(cache['second'])
  end
end
