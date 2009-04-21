#!/usr/bin/env ruby

#
# NOTE: There will be many warnings with this test because we actually do
#       redefined a ton of stuff
#

require "test/unit"
require "xamplr-generator"

include XamplGenerator
include Xampl

class TestXampl < Test::Unit::TestCase

  def setup
    Xampl.disable_all_persisters
    FromXML.reset_registry
  end

  def test_predefined_element_info_1
    options = Xampl.make(Options) { | options |
      options.new_index_attribute("name")
      options.new_index_attribute("id")
      options.new_index_attribute("pid").persisted = true

      options.new_resolve{ | resolver |
        resolver.pkg = "XamplExample2"
        resolver.namespace="http://xampl.com/example"
      }
      options.new_resolve{ | resolver |
        resolver.pkg = "XamplExamplePlay2"
        resolver.namespace="http://xampl.com/example/play"
      }
    }

    elements = Xampl.make(Elements) { | elements |
      elements.pid = "http://xampl.com/example"
      elements.new_element("thing"){ | element |
        element.kind = 'mixed'
        element.indexed_by_attr = 'info'
        element.persisted = true
        element.class_name = "MyKindOfThing"
      }
    }

    generator = Generator.new(options, elements)

    generator.comprehend_from_files(["./xml/example.xml"])
    generator.generate_to_directory("./tmp/")

    require "tmp/XamplExample2"

    thing = XamplExample2::MyKindOfThing.new
    assert(thing.persist_required)
    assert(thing.has_mixed_content)
    assert_equal(:info, thing.indexed_by)

    thing2 = thing.new_thing("two")
    assert(thing2)
  end

  def test_predefined_element_info_2
    options = Xampl.make(Options) { | options |
      options.new_index_attribute("name")
      options.new_index_attribute("id")
      options.new_index_attribute("pid").persisted = true

      options.new_resolve{ | resolver |
        resolver.pkg = "XamplExample2"
        resolver.namespace="http://xampl.com/example"
      }
      options.new_resolve{ | resolver |
        resolver.pkg = "XamplExamplePlay2"
        resolver.namespace="http://xampl.com/example/play"
      }
    }

    elements = Xampl.make(Elements) { | elements |
      elements.pid = "http://xampl.com/example"
      elements.new_element("thing"){ | element |
        element.kind = 'mixed'
        element.indexed_by_attr = 'info'
        element.persisted = true
        element.class_name = "MyKindOfThing"
        element.attribute_name = "my_thing"
      }
    }

    generator = Generator.new(options, elements)

    generator.comprehend_from_files(["./xml/example.xml"])
    generator.generate_to_directory("./tmp2/")

    require "tmp2/XamplExample2"
    #include XamplExample2

    thing = XamplExample2::MyKindOfThing.new
    assert(thing.persist_required)
    assert(thing.has_mixed_content)
    assert_equal(:info, thing.indexed_by)

    thing2 = thing.new_my_thing("two")
    assert(thing2)
  end

end


