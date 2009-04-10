#!/usr/bin/env ruby -w -I..

require "test/unit"
require "xampl-generator"

include XamplGenerator
include Xampl

class TestRollback < Test::Unit::TestCase

  xml = %Q{
<sack pid='white'>
  <bag mark='one'>
    <thing info='something'>hello</thing>
    <stuff id='my stuff'>blah</stuff>
    <bag/>
  </bag>
  <sack pid='black'/>
</sack>
    }

  Generator.new.go(:strings => [ xml ],
                   :directory => "step7")

  require "step7/XamplAdHoc"
  include XamplAdHoc

  def test_change
    pname = "test_change"
    Xampl.transaction(pname, :in_memory){
      sack1 = Sack.new
      sack1.pid = "sack1"

      sack2 = sack1.new_sack("sack2"){ | sack |
        sack.new_bag{ | bag |
          bag.new_thing{ | thing |
            thing.info = "thing in sack2"
          }
        }
      }
    }

    #assert_equal(0, Xampl.count_changed)

    Xampl.transaction(pname){
      sack2 = Sack["sack2"]
      sack2.bag[0].thing[0].info = "changed value"
    }

    #assert_equal(0, Xampl.count_changed)
    Xampl.transaction(pname){
      Xampl.rollback
    }

    Xampl.transaction(pname){
      sack1 = Sack["sack1"]
      assert_equal("changed value", sack1.sack[0].bag[0].thing[0].info)
    }

  end

  def test_change_in_fs
    pname = "test_deep_change_in_fs" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    Xampl.transaction(pname, :filesystem){
      sack1 = Sack.new
      sack1.pid = "sack1"

      sack2 = sack1.new_sack("sack2"){ | sack |
        sack.new_bag{ | bag |
          bag.new_thing{ | thing |
            thing.info = "thing in sack2"
          }
        }
      }
    }

    #assert_equal(0, Xampl.count_changed)

    Xampl.transaction(pname){
      sack2 = Sack["sack2"]
      sack2.bag[0].thing[0].info = "changed value"

      assert_equal(1, Xampl.count_changed)
      Xampl.persister.put_changed
    }

    #assert_equal(0, Xampl.count_changed)

    Xampl.transaction(pname){
      Xampl.rollback
    }

    Xampl.transaction(pname){
      sack1 = Sack["sack1"]
      assert_equal("changed value", sack1.sack[0].bag[0].thing[0].info)
    }

  end

  def test_change_out_of_persister
    pname = "test_change_out_of_persister"

    sack2 = nil

    Xampl.transaction(pname, :in_memory){
      sack1 = Sack.new
      sack1.pid = "sack1"

      sack2 = sack1.new_sack("sack2"){ | sack |
        sack.new_bag{ | bag |
          bag.new_thing{ | thing |
            thing.info = "thing in sack2"
          }
        }
      }
    }

    assert_raise(UnmanagedChange){
      sack2.bag[0].thing[0].info = "this is a very bad idea"
    }
    puts sack2.pp_xml

    Xampl.transaction(pname){
      Xampl.rollback
    }

    sack2a = nil
    Xampl.transaction(pname){
      sack2a = Sack["sack2"]
      sack2a.bag[0].new_thing.info = "change the sack"
    }
    puts sack2a.pp_xml
  end

end
