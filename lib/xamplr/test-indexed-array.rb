#!/usr/bin/env ruby

require "test/unit"
#require "rubygems"
#require_gem "arrayfields"
#require "arrayfields-local"
require "indexed-array"

class TestXampl < Test::Unit::TestCase

  def xtest_dummy_fieldarray
    ia = []
    ia.fields = []

    ia << 0 << 1 << 2

    ia["three"] = 3
    ia["four"] = 4
    ia["five"] = 5

    assert_equal(0, ia[0])
    assert_equal(1, ia[1])
    assert_equal(2, ia[2])
    assert_equal(3, ia[3])
    assert_equal(4, ia[4])
    assert_equal(5, ia[5])

    assert_equal(3, ia["three"])
    assert_equal(4, ia["four"])
    assert_equal(5, ia["five"])

    ia["four"] = 44

    assert_equal(44, ia["four"])
    assert_equal(44, ia[4])

  end

  def test_remove
    ia = IndexedArray.new

    ia["one"] = 1
    ia["two"] = 2
    ia["three"] = 3

    assert_equal(1, ia["one"])
    assert_equal(2, ia["two"])
    assert_equal(3, ia["three"])

    ia.delete_at("one")

    assert_equal(2, ia["two"])
    assert_equal(3, ia["three"])

    assert_equal(2, ia.size)
    assert_equal(2, ia[0])
    assert_equal(3, ia[1])
  end

  def xtest_remove_fieldarray
    ia = []
    ia.fields = []

    ia["one"] = 1
    ia["two"] = 2
    ia["three"] = 3

    assert_equal(1, ia["one"])
    assert_equal(2, ia["two"])
    assert_equal(3, ia["three"])

    ia.delete_at("one")

    assert_equal(2, ia["two"])
    assert_equal(3, ia["three"])

    assert_equal(2, ia.size)
    assert_equal(2, ia[0])
    assert_equal(3, ia[1])
  end

  def test_two
    a = IndexedArray.new
    b = IndexedArray.new

    a["one"] = 1
    a["two"] = 2
    a["three"] = 3

    #		a.each_pair { | k, v |
    #		  puts "a:: k: #{k}, v: #{v}"
    #		}
    #		a.dump("a")
    #		b.each_pair { | k, v |
    #		  puts "b:: k: #{k}, v: #{v}"
    #		}
    #		b.dump("b")


    b["three"] = 300
    b["two"] = 200
    b["one"] = 100

    assert_equal(1, a["one"])
    assert_equal(2, a["two"])
    assert_equal(3, a["three"])

    assert_equal(1, a[0])
    assert_equal(2, a[1])
    assert_equal(3, a[2])

    assert_equal(300, b["three"])
    assert_equal(200, b["two"])
    assert_equal(100, b["one"])
    assert_equal(300, b[0]) ### returns 100 here
    assert_equal(200, b[1])
    assert_equal(100, b[2])

    #		a.dump("a")
    #		b.dump("b")

  end

  def xtest_two_fieldarray
    a = []
    a.fields = []

    b = []
    b.fields = []

    a["one"] = 1
    a["two"] = 2
    a["three"] = 3

    #		a.each_pair { | k, v |
    #		  puts "a:: k: #{k}, v: #{v}"
    #		}
    #		a.dump("a")
    #		b.each_pair { | k, v |
    #		  puts "b:: k: #{k}, v: #{v}"
    #		}
    #		b.dump("b")


    b["three"] = 300
    b["two"] = 200
    b["one"] = 100

    assert_equal(1, a["one"])
    assert_equal(2, a["two"])
    assert_equal(3, a["three"])

    assert_equal(1, a[0])
    assert_equal(2, a[1])
    assert_equal(3, a[2])

    assert_equal(300, b["three"])
    assert_equal(200, b["two"])
    assert_equal(100, b["one"])
    assert_equal(300, b[0]) ### returns 100 here
    assert_equal(200, b[1])
    assert_equal(100, b[2])

    #		a.dump("a")
    #		b.dump("b")

  end

end
