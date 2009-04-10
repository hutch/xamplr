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

  def test_rollback
    #sack1 = sack2 = nil

    Xampl.transaction("step7-persister", :in_memory){
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
    begin
      Xampl.transaction("step7-persister"){
        sack2 = Sack["sack2"]

        assert_equal(0, Xampl.count_changed)

        sack2.bag[0].thing[0].info = "this is a mistake"

        assert_equal(1, Xampl.count_changed)

        raise
      }
    rescue Exception
    end

    #assert_equal(0, Xampl.count_changed)

    Xampl.transaction("step7-persister"){
      sack1 = Sack["sack1"]
      assert_equal("thing in sack2", sack1.sack[0].bag[0].thing[0].info)
    }

  end

  def test_rollback_in_fs
    #sack1 = sack2 = nil

    pname = "test_rollback_in_fs" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
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
    begin
      Xampl.transaction(pname, :filesystem){
        sack2 = Sack["sack2"]

        sack2.bag[0].thing[0].info = "this is a mistake"

        raise
      }
    rescue Exception
    end

    #assert_equal(0, Xampl.count_changed)

    Xampl.transaction(pname, :filesystem){
      sack1 = Sack["sack1"]
      assert_equal("thing in sack2", sack1.sack[0].bag[0].thing[0].info)
    }

  end
end
