#!/usr/bin/env ruby -w

require "test/unit"
require "xamplr-generator"

include XamplGenerator
include Xampl

class TestXampl < Test::Unit::TestCase

  def setup
    Xampl.disable_all_persisters
  end

  def test_same_names
    options = Xampl.make(Options) { | options |
      options.new_index_attribute("name")
      options.new_resolve{ | resolver |
        resolver.pkg = "XamplExampleNames"
        resolver.namespace="http://xampl.com/example"
      }
    }
    generator = Generator.new(options)
    xml = %Q{
<conflict name="hansel" xmlns='http://xampl.com/example'>
  <xname name='blah'>
	  <conflict name='nested'/>
	</xname>
  <name name='blah'>
	  <conflict name='nested'/>
	</name>
</conflict>
}
    generator.comprehend_from_strings([ xml ])
    generator.generate_and_eval() { | module_definition, name |
      eval(module_definition, nil, name, 1)
    }

    parser = FromXML.new
    conflict = parser.parse_string(xml)

    assert(conflict)
    assert_equal("hansel", conflict.name)
    assert_equal("hansel"[0], conflict.name[0])
    assert_equal("blah", conflict.xname_child[0].name)
    assert_equal("blah", conflict.name_child[0].name)
    assert_nil(conflict.name['blah'])
  end

  def check_parents(xampl, parent=nil)
    if (nil != parent) then
      found = false
      xampl.parents.each{ | p |
        found = true if (parent == p)
      }
      assert(found)
    else
      if (xampl.kind_of? XamplObject)
        assert((nil == xampl.parents) || (0 == xampl.parents.size))
      end
    end
    xampl.children.each{ | child |
      check_parents(child, xampl) if (child.kind_of? XamplObject)
    }
  end
end

