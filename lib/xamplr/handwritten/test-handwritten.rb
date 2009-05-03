#!/usr/bin/env ruby

require "test/unit"

require "xamplr-generator"
require "example"

include XamplGenerator
include Xampl
include XamplExample

class TestXampl < Test::Unit::TestCase

  def test_simple_xampl
    emph1 = Emph.new
    assert_not_nil(emph1.is_changed)
    emph2 = Emph.new
    assert_not_nil(emph2.is_changed)
    emph3 = Emph.new
    assert_not_nil(emph3.is_changed)

    emph1.content = "emph 1"
    assert_not_nil(emph1.is_changed)
    emph2.content = "emph 2"
    assert_not_nil(emph2.is_changed)

    assert_equal("emph 1", emph1.content)
    assert_equal("emph 2", emph2.content)

    assert_equal("<ns0:emph xmlns:ns0='http://xampl.com/example'>emph 1</ns0:emph>", emph1.to_xml)
    assert_equal("<ns0:emph xmlns:ns0='http://xampl.com/example'>emph 2</ns0:emph>", emph2.to_xml)
    assert_equal("<ns0:emph xmlns:ns0='http://xampl.com/example'/>", emph3.to_xml)

    fakeRules = XMLPrinter.new("fake...")
    emph1.to_xml_internal(fakeRules)
    r = fakeRules.done

    assert_equal("fake... xmlns:ns0='http://xampl.com/example'<ns0:emph>emph 1</ns0:emph>", r)

    assert_not_nil(emph1.is_changed)
    assert_not_nil(emph2.is_changed)
    assert_not_nil(emph3.is_changed)

    check_parents(emph1)
    check_parents(emph2)
    check_parents(emph3)
  end

  def test_empty_xampl
    stuff1 = Stuff.new
    assert_not_nil(stuff1.is_changed)
    stuff1.kind = 'test'
    assert_not_nil(stuff1.is_changed)

    stuff2 = Stuff.new
    assert_not_nil(stuff2.is_changed)

    stuff3 = Stuff.new
    assert_not_nil(stuff3.is_changed)
    stuff3.kind = 'test'
    assert_not_nil(stuff3.is_changed)
    stuff3.special = 'test'
    assert_not_nil(stuff3.is_changed)

    assert_equal("<ns1:stuff kind='test' xmlns:ns1='http://xampl.com/example' xmlns:ns0='http://xampl.com/example/special'/>",
                 stuff1.to_xml)
    assert_equal("<ns1:stuff xmlns:ns1='http://xampl.com/example' xmlns:ns0='http://xampl.com/example/special'/>",
                 stuff2.to_xml)
    assert_equal("<ns1:stuff kind='test' ns0:special='test' xmlns:ns1='http://xampl.com/example' xmlns:ns0='http://xampl.com/example/special'/>",
                 stuff3.to_xml)

    fakeRules = XMLPrinter.new("fake...")
    stuff1.to_xml_internal(fakeRules)
    r = fakeRules.done
    assert_equal("fake... xmlns:ns1='http://xampl.com/example' xmlns:ns0='http://xampl.com/example/special'<ns1:stuff kind='test'/>", r)

    check_parents(stuff1)
    check_parents(stuff2)
    check_parents(stuff3)
  end

  def test_mixed_xampl
    desc1 = Description.new
    assert_not_nil(desc1.is_changed)
    desc1.kind = "desc1"
    assert_not_nil(desc1.is_changed)
    assert_equal("<ns0:description kind='desc1' xmlns:ns0='http://xampl.com/example'/>",
                 desc1.to_xml)

    desc1.add_content("hello ")
    emph_content_1 = "there"
    desc1.new_emph.content = emph_content_1
    desc1.add_content("! How ")
    emph_content_2 = "are"
    desc1.new_emph.content = emph_content_2
    desc1.add_content(" you?")

    assert_not_nil(desc1.is_changed)
    assert_equal("<ns0:description kind='desc1' xmlns:ns0='http://xampl.com/example'>hello <ns0:emph>there</ns0:emph>! How <ns0:emph>are</ns0:emph> you?</ns0:description>",
                 desc1.to_xml)
    assert_equal(desc1.emph_child.length, 2)
    assert_equal(emph_content_1, desc1.emph_child[0].content, emph_content_1)
    assert_equal(emph_content_2, desc1.emph_child[1].content, emph_content_2)

    check_parents(desc1)
  end

  def test_data_xampl
    emph_content_1 = "there"
    emph_content_2 = "are"
    big_thing = Xampl.make(Thing){ | big_thing |
      big_thing.new_thing("thing"){ | thing |
        thing.new_stuff.kind = "stuff1"

        thing.new_description{ | desc |
          desc.kind = "desc1"

          desc.add_content("hello ")
          desc.new_emph.content = emph_content_1
          desc.add_content("! How ")
          desc.new_emph.content = emph_content_2
          desc.add_content(" you?")
        }
      }
    }

    ###    desc1 = Description.new
    ###    desc1.kind = "desc1"
    ###
    ###    desc1.add_content("hello ")
    ###		emph_content_1 = "there"
    ###    desc1.new_emph.content = emph_content_1
    ###    desc1.add_content("! How ")
    ###		emph_content_2 = "are"
    ###    desc1.new_emph.content = emph_content_2
    ###    desc1.add_content(" you?")
    ###
    ###    thing = Thing.new
    ###		thing.pid = "thing"
    ###		assert(thing.is_changed)
    ###    thing.new_stuff.kind = "stuff1"
    ###		assert_not_nil(thing.is_changed)
    ###		thing.is_changed = nil
    ###    thing.add_description(desc1)
    ###		assert_not_nil(thing.is_changed)
    ###
    ###    big_thing = Thing.new
    ###    big_thing.add_thing(thing)
    assert_equal("<ns0:thing xmlns:ns0='http://xampl.com/example' xmlns:ns1='http://xampl.com/example/special'><ns0:thing pid='thing'><ns0:stuff kind='stuff1'/><ns0:description kind='desc1'>hello <ns0:emph>there</ns0:emph>! How <ns0:emph>are</ns0:emph> you?</ns0:description></ns0:thing></ns0:thing>",
                 big_thing.to_xml)

    assert_equal(1, big_thing.children.length)
    assert_equal(2, big_thing.thing_child[0].children.length)
    assert_equal(big_thing.thing_child[0].description_child[0].emph_child.length, 2)
    assert_equal(emph_content_1, big_thing.thing_child[0].description_child[0].emph_child[0].content, emph_content_1)
    assert_equal(emph_content_2, big_thing.thing_child[0].description_child[0].emph_child[1].content, emph_content_2)

    check_parents(big_thing)
  end

  def test_data_xampl_using_append
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
    assert_not_nil(desc1.is_changed)

    thing = Thing.new
    thing.pid = "thing"
    thing.new_stuff.kind = "stuff1"
    thing << desc1

    big_thing = Thing.new
    big_thing << thing

    assert_equal("<ns0:thing xmlns:ns0='http://xampl.com/example' xmlns:ns1='http://xampl.com/example/special'><ns0:thing pid='thing'><ns0:stuff kind='stuff1'/><ns0:description kind='desc1'>hello <ns0:emph>there</ns0:emph>! How <ns0:emph>are</ns0:emph> you?</ns0:description></ns0:thing></ns0:thing>",
                 big_thing.to_xml)

    assert_equal(2, big_thing.thing_child[0].description_child[0].emph_child.length)
    assert_equal(emph_content_1, big_thing.thing_child[0].description_child[0].emph_child[0].content)
    assert_equal(emph_content_2, big_thing.thing_child[0].description_child[0].emph_child[1].content)

    check_parents(big_thing)
  end

  def test_from_xml
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
    big_thing << "leading content" << thing << "trailing content"

    #puts big_thing.to_xml
    #pp = FromXML.new
    #pp.setup_parse_string(big_thing.to_xml)
    #while not pp.endDocument?
    #event = pp.next_interesting_event
    #puts event
    #if (event == Xampl_PP::TEXT) then
    #puts "TEXT [[[" << pp.text << "]]]"
    #end
    #end

    pp = FromXML.new
    pp.setup_parse_string(big_thing.to_xml)
    assert_equal(pp.next_interesting_event, Xampl_PP::START_ELEMENT)
    assert_equal(pp.next_interesting_event, Xampl_PP::TEXT)
    assert_equal(pp.next_interesting_event, Xampl_PP::START_ELEMENT)
    assert_equal(pp.next_interesting_event, Xampl_PP::START_ELEMENT)

    assert_equal(pp.next_interesting_event, Xampl_PP::END_ELEMENT)
    assert_equal(pp.next_interesting_event, Xampl_PP::START_ELEMENT)
    assert_equal(pp.next_interesting_event, Xampl_PP::TEXT)
    assert_equal(pp.next_interesting_event, Xampl_PP::START_ELEMENT)
    assert_equal(pp.next_interesting_event, Xampl_PP::TEXT)
    assert_equal(pp.next_interesting_event, Xampl_PP::END_ELEMENT)
    assert_equal(pp.next_interesting_event, Xampl_PP::TEXT)
    assert_equal(pp.next_interesting_event, Xampl_PP::START_ELEMENT)
    assert_equal(pp.next_interesting_event, Xampl_PP::TEXT)
    assert_equal(pp.next_interesting_event, Xampl_PP::END_ELEMENT)
    assert_equal(pp.next_interesting_event, Xampl_PP::TEXT)
    assert_equal(pp.next_interesting_event, Xampl_PP::END_ELEMENT)
    assert_equal(pp.next_interesting_event, Xampl_PP::END_ELEMENT)
    assert_equal(pp.next_interesting_event, Xampl_PP::END_ELEMENT)
    assert_equal(pp.next_interesting_event, Xampl_PP::END_DOCUMENT)
    assert(pp.endDocument?)

    pp = FromXML.new
    another_big_thing = pp.parse_string(big_thing.to_xml)
    assert_equal(big_thing.to_xml, another_big_thing.to_xml)
  end

  def test_index
    thing = Thing.new
    thing.new_key_value("one").value = "1"
    thing.new_key_value("two").value = "2"

    assert_equal(thing.key_value_child[0], thing.key_value_map["one"])
    assert_equal(thing.key_value_child[1], thing.key_value_map["two"])

    check_parents(thing)
  end

  def test_parents
    thing = Thing.new
    (kv1 = thing.new_key_value("one")).value = "1"
    (kv2 = thing.new_key_value("two")).value = "2"

    assert_equal(thing, thing.key_value_child[0].parents[0])
    assert_equal(thing, thing.key_value_child[1].parents[0])

    another_thing = Thing.new
    another_thing << kv1 << kv2

    assert_equal(2, kv1.parents.size)
    assert_equal(2, kv2.parents.size)

    check_parents(thing)
    check_parents(another_thing)
  end

  def test_non_string_attributes
    stuff1 = Stuff.new

    stuff1.kind = 123.456
    assert_equal("<ns1:stuff kind='123.456' xmlns:ns1='http://xampl.com/example' xmlns:ns0='http://xampl.com/example/special'/>",
                 stuff1.to_xml)

    stuff1.kind = nil
    assert_equal("<ns1:stuff xmlns:ns1='http://xampl.com/example' xmlns:ns0='http://xampl.com/example/special'/>",
                 stuff1.to_xml)

    stuff1.kind = [1, 2, 3]
    assert_equal("<ns1:stuff kind='123' xmlns:ns1='http://xampl.com/example' xmlns:ns0='http://xampl.com/example/special'/>",
                 stuff1.to_xml)

    stuff2 = Stuff.new
    stuff2.kind = 123
    stuff1.kind = stuff2
    assert_equal("<ns1:stuff kind='&lt;ns1:stuff kind=&apos;123&apos; xmlns:ns1=&apos;http://xampl.com/example&apos; xmlns:ns0=&apos;http://xampl.com/example/special&apos;/&gt;' xmlns:ns1='http://xampl.com/example' xmlns:ns0='http://xampl.com/example/special'/>",
                 stuff1.to_xml)

    thing = Thing.new
    thing.pid = "thing"
    thing << stuff2
    stuff1.kind = thing
    # TODO -- check what happens with a PIDed thing
    assert_equal("<ns1:stuff kind='&lt;ns0:thing pid=&apos;thing&apos; xmlns:ns0=&apos;http://xampl.com/example&apos; xmlns:ns1=&apos;http://xampl.com/example/special&apos;&gt;&lt;ns0:stuff kind=&apos;123&apos;/&gt;&lt;/ns0:thing&gt;' xmlns:ns1='http://xampl.com/example' xmlns:ns0='http://xampl.com/example/special'/>",
                 stuff1.to_xml)

    # TODO -- check round tripping of this stuff
    check_parents(stuff1)
  end

  def test_registry
    assert_equal([ Emph ], FromXML::registered(Emph::ns_tag))
    assert_equal([ Emph ], FromXML::registered(Emph::tag))
    assert_equal([ Stuff ], FromXML::registered(Stuff::ns_tag))
    assert_equal([ Stuff ], FromXML::registered(Stuff::tag))

    FromXML::register(Emph::tag, Emph::ns_tag, Emph)
    assert_equal([ Emph ], FromXML::registered(Emph::ns_tag))
    assert_equal([ Emph ], FromXML::registered(Emph::tag))

    FromXML::register(Emph::tag, Thing::ns_tag, Thing)
    assert_equal([ Emph ], FromXML::registered(Emph::ns_tag))
    assert_equal([ Emph, Thing ], FromXML::registered(Emph::tag))
  end

  def test_in_memory_persistence_basics
    stuff = Stuff.new
    thing = Thing.new
    thing << stuff

    assert(!stuff.persist_required)
    assert(thing.persist_required)
    assert(nil == thing.persister)

    persister = InMemoryPersister.new

    assert(!persister.write(thing))

    thing.pid = "thing"

    assert(persister.write(thing))

    saved_thing = persister.read(Thing, "thing")
    assert(saved_thing)

    assert_equal(thing.to_xml, saved_thing.to_xml)

    Xampl.in_memory_persister("first")

    stuff = Stuff.new
    thing = Thing.new
    thing.pid = "thing"
    thing << stuff

    assert_nil(Xampl.lookup(Thing, "thing"))

    assert(nil == thing.persister)
    assert(thing.is_changed)
    assert(0 == Xampl.count_changed)
    Xampl.introduce_to_persister(thing)
    assert(thing.persister)
    assert_equal(1, Xampl.count_changed)
    assert_equal(thing, Xampl.lookup(Thing, "thing"), "cannot lookup new stuff")

    #Xampl.print_stats

    assert_equal(1, Xampl.count_changed)
    writes = Xampl.sync
    assert_equal(1, writes)
    assert_equal(0, Xampl.count_changed)
    assert(Xampl.lookup(Thing, "thing"))

    assert_equal(thing, Xampl.lookup(Thing, "thing"), "cannot lookup cached stuff")

    Xampl.clear_cache

    found = Xampl.lookup(Thing, "thing")
    assert_not_equal(thing, found)

    #Xampl.print_stats
  end

  def test_escaping
    description = Description.new
    description.kind = "<>&'\""
    description << "<>&'\""

    expect = "<ns0:description kind='&lt;&gt;&amp;&apos;&quot;' xmlns:ns0='http://xampl.com/example'>&lt;>&amp;'\"</ns0:description>"

    assert_equal(expect, description.to_xml)
  end

  def test_generator
    options = Xampl.make(Options) { | options |
      options.new_index_attribute("name")
      options.new_index_attribute("id")
      options.new_index_attribute("pid").persisted = true

      options.new_resolve{ | resolver |
        resolver.pkg = "XamplExample"
        resolver.namespace="http://xampl.com/example"
      }
      options.new_resolve{ | resolver |
        resolver.pkg = "XamplExamplePlay"
        resolver.namespace="http://xampl.com/example/play"
      }
    }
    generator = Generator.new(options)

    generator.comprehend_from_strings([
            %Q{
<things xmlns='http://xampl.com/example'
        xmlns:xampl='http://xampl.com/example/special'>
  <thing pid=''>
    <description kind=''>blah <emph>blah</emph> blah</description>
    <keyValue id='' value=''/>
    <stuff kind='' xampl:special=''/>
    <thing pid=''/>
    <things/>
  </thing>
</things>
}
    ])

    ns = "http://xampl.com/example"
    emap = generator.elements_map
    assert_equal(1, emap.size)
    elements = emap[ns]
    assert_not_nil(elements)
    assert_equal(6, elements.element_child.size)

    ename = "emph"
    element = elements.element_map[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(!element.empty)
    assert(element.has_content)

    ename = "description"
    element = elements.element_map[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(!element.empty)
    assert(element.has_content)

    assert_equal(1, element.attribute_child.size)
    assert_not_nil(element.attribute_map["kind"])
    assert_nil(element.attribute_map["kind"].namespace)

    assert_equal(1, element.child_element_child.size)
    cname = "{#{ns}}emph"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("emph", element.child_element_map[cname].element_name)

    ename = "stuff"
    element = elements.element_map[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(element.empty)
    assert(!element.has_content)

    assert_equal(2, element.attribute_child.size)
    assert_not_nil(element.attribute_map["kind"])
    assert_nil(element.attribute_map["kind"].namespace)
    assert_not_nil(element.attribute_map["special"])
    assert_equal('http://xampl.com/example/special', element.attribute_map["special"].namespace)

    assert_equal(0, element.child_element_child.size)

    ename = "keyValue"
    element = elements.element_map[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(element.empty)
    assert(!element.has_content)

    assert_equal(2, element.attribute_child.size)
    assert_not_nil(element.attribute_map["id"])
    assert_nil(element.attribute_map["id"].namespace)
    assert_not_nil(element.attribute_map["value"])
    assert_nil(element.attribute_map["value"].namespace)

    assert_equal(0, element.child_element_child.size)

    ename = "thing"
    element = elements.element_map[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(element.empty)
    assert(!element.has_content)

    assert_equal(1, element.attribute_child.size)
    assert_equal(1, element.attribute_map.size)
    assert_not_nil(element.attribute_map["pid"])
    assert_nil(element.attribute_map["pid"].namespace)

    assert_equal(5, element.child_element_child.size)

    cname = "{#{ns}}description"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("description", element.child_element_map[cname].element_name)

    cname = "{#{ns}}keyValue"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("keyValue", element.child_element_map[cname].element_name)

    cname = "{#{ns}}stuff"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("stuff", element.child_element_map[cname].element_name)

    cname = "{#{ns}}thing"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("thing", element.child_element_map[cname].element_name)

    cname = "{#{ns}}things"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("things", element.child_element_map[cname].element_name)

    ename = "things"
    element = elements.element_map[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(element.empty)
    assert(!element.has_content)

    assert_equal(0, element.attribute_child.size)
    assert_equal(1, element.child_element_child.size)

    cname = "{#{ns}}thing"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("thing", element.child_element_map[cname].element_name)

    #generator.print_stats
    #generator.analyse

    ename = "emph"
    element = elements.element_map[ename]
    assert_equal("simple", element.kind, "emph is wrong kind")
    assert_nil(element.indexed_by)
    assert_nil(element.persisted)
    assert_equal("XamplExample", element.package)
    assert_equal("Emph", element.class_name)
    assert_equal("emph", element.attribute_name)

    ename = "description"
    element = elements.element_map[ename]
    assert_equal("mixed", element.kind, "description is wrong kind")
    assert_nil(element.indexed_by)
    assert_nil(element.persisted)
    assert_equal("XamplExample", element.package)
    assert_equal("Description", element.class_name)
    assert_equal("description", element.attribute_name)

    ename = "stuff"
    element = elements.element_map[ename]
    assert_equal("empty", element.kind, "stuff is wrong kind")
    assert_nil(element.indexed_by)
    assert_nil(element.persisted)
    assert_equal("XamplExample", element.package)
    assert_equal("Stuff", element.class_name)
    assert_equal("stuff", element.attribute_name)

    ename = "keyValue"
    element = elements.element_map[ename]
    assert_equal("empty", element.kind, "keyValue is wrong kind")
    assert_equal("id", element.indexed_by)
    assert_nil(element.persisted)
    assert_equal("XamplExample", element.package)
    assert_equal("KeyValue", element.class_name)
    assert_equal("key_value", element.attribute_name)

    ename = "thing"
    element = elements.element_map[ename]
    assert_equal("data", element.kind, "thing is wrong kind")
    assert_equal("pid", element.indexed_by)
    assert_not_nil(element.persisted)
    assert_equal("XamplExample", element.package)
    assert_equal("Thing", element.class_name)
    assert_equal("thing", element.attribute_name)

    generator.generate_to_directory(nil)
  end

  def test_generator_with_no_namespace
    generator = Generator.new
    generator.comprehend_from_strings([
            %Q{
<things xmlns:xampl='http://xampl.com/example/special'>
  <thing pid=''>
    <description kind=''>blah <emph>blah</emph> blah</description>
    <keyValue id='' value=''/>
    <stuff kind='' xampl:special=''/>
    <thing pid=''/>
    <things/>
  </thing>
</things>
}
    ])

    ns = ""
    #ns = nil
    emap = generator.elements_map
    assert_equal(1, emap.size)
    elements = emap[ns]
    assert_not_nil(elements)
    assert_equal(6, elements.element_child.size)

    ename = "emph"
    element = elements.element_map[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(!element.empty)
    assert(element.has_content)

    ename = "description"
    element = elements.element_map[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(!element.empty)
    assert(element.has_content)

    assert_equal(1, element.attribute_child.size)
    assert_not_nil(element.attribute_map["kind"])
    assert_nil(element.attribute_map["kind"].namespace)

    assert_equal(1, element.child_element_child.size)
    cname = "{#{ns}}emph"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("emph", element.child_element_map[cname].element_name)

    ename = "stuff"
    element = elements.element_map[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(element.empty)
    assert(!element.has_content)

    assert_equal(2, element.attribute_child.size)
    assert_not_nil(element.attribute_map["kind"])
    assert_nil(element.attribute_map["kind"].namespace)
    assert_not_nil(element.attribute_map["special"])
    assert_equal('http://xampl.com/example/special', element.attribute_map["special"].namespace)

    assert_equal(0, element.child_element_child.size)

    ename = "keyValue"
    element = elements.element_map[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(element.empty)
    assert(!element.has_content)

    assert_equal(2, element.attribute_child.size)
    assert_not_nil(element.attribute_map["id"])
    assert_nil(element.attribute_map["id"].namespace)
    assert_not_nil(element.attribute_map["value"])
    assert_nil(element.attribute_map["value"].namespace)

    assert_equal(0, element.child_element_child.size)

    ename = "thing"
    element = elements.element_map[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(element.empty)
    assert(!element.has_content)

    assert_equal(1, element.attribute_child.size)
    assert_equal(1, element.attribute_map.size)
    assert_not_nil(element.attribute_map["pid"])
    assert_nil(element.attribute_map["pid"].namespace)

    assert_equal(5, element.child_element_child.size)

    cname = "{#{ns}}description"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("description", element.child_element_map[cname].element_name)

    cname = "{#{ns}}keyValue"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("keyValue", element.child_element_map[cname].element_name)

    cname = "{#{ns}}stuff"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("stuff", element.child_element_map[cname].element_name)

    cname = "{#{ns}}thing"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("thing", element.child_element_map[cname].element_name)

    cname = "{#{ns}}things"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("things", element.child_element_map[cname].element_name)

    ename = "things"
    element = elements.element_map[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(element.empty)
    assert(!element.has_content)

    assert_equal(0, element.attribute_child.size)
    assert_equal(1, element.child_element_child.size)

    cname = "{#{ns}}thing"
    assert_not_nil(element.child_element_map[cname])
    assert_equal(ns, element.child_element_map[cname].namespace)
    assert_equal("thing", element.child_element_map[cname].element_name)

    #generator.print_stats
    #generator.analyse

    ename = "emph"
    element = elements.element_map[ename]
    assert_equal("simple", element.kind, "emph is wrong kind")
    assert_nil(element.indexed_by)
    assert_nil(element.persisted)
    assert_equal("XamplAdHoc", element.package)
    assert_equal("Emph", element.class_name)
    assert_equal("emph", element.attribute_name)

    ename = "description"
    element = elements.element_map[ename]
    assert_equal("mixed", element.kind, "description is wrong kind")
    assert_nil(element.indexed_by)
    assert_nil(element.persisted)
    assert_equal("XamplAdHoc", element.package)
    assert_equal("Description", element.class_name)
    assert_equal("description", element.attribute_name)

    ename = "stuff"
    element = elements.element_map[ename]
    assert_equal("empty", element.kind, "stuff is wrong kind")
    assert_nil(element.indexed_by)
    assert_nil(element.persisted)
    assert_equal("XamplAdHoc", element.package)
    assert_equal("Stuff", element.class_name)
    assert_equal("stuff", element.attribute_name)

    ename = "keyValue"
    element = elements.element_map[ename]
    assert_equal("empty", element.kind, "keyValue is wrong kind")
    assert_equal("id", element.indexed_by)
    assert_nil(element.persisted)
    assert_equal("XamplAdHoc", element.package)
    assert_equal("KeyValue", element.class_name)
    assert_equal("key_value", element.attribute_name)

    ename = "thing"
    element = elements.element_map[ename]
    assert_equal("data", element.kind, "thing is wrong kind")
    assert_equal("pid", element.indexed_by)
    assert_not_nil(element.persisted)
    assert_equal("XamplAdHoc", element.package)
    assert_equal("Thing", element.class_name)
    assert_equal("thing", element.attribute_name)

    generator.generate_to_directory(nil)
  end

  def choose_name_test_helper(name, expected_class_name, expected_attribute_name)
    original_name = name.dup
    class_name, attribute_name = Generator.choose_names(name)
    assert_equal(original_name, name, "changed the original name")
    assert_equal(expected_class_name, class_name, "CLASS name wrong")
    assert_equal(expected_attribute_name, attribute_name, "ATTRIBUTE name wrong")
  end

  def test_choose_names
    choose_name_test_helper("abcd", "Abcd", "abcd")
    choose_name_test_helper("Abcd", "Abcd", "abcd")
    choose_name_test_helper("abCd", "AbCd", "ab_cd")
    choose_name_test_helper("AbCd", "AbCd", "ab_cd")
    choose_name_test_helper("ABcd", "ABcd", "abcd")

    choose_name_test_helper("ABcdefABCdef", "ABcdefABCdef", "abcdef_abcdef")

    choose_name_test_helper("ab-cd", "AbCd", "ab_cd")
    choose_name_test_helper("Ab-Cd", "AbCd", "ab_cd")

    choose_name_test_helper("ab--cd", "AbCd", "ab_cd")
    choose_name_test_helper("Ab--Cd", "AbCd", "ab_cd")

    choose_name_test_helper("ab_-cd", "AbCd", "ab_cd")
    choose_name_test_helper("Ab_-Cd", "AbCd", "ab_cd")

    choose_name_test_helper("ab__cd", "AbCd", "ab_cd")
    choose_name_test_helper("Ab__Cd", "AbCd", "ab_cd")

    choose_name_test_helper("ab:cd", "AbCd", "ab_cd")
    choose_name_test_helper("Ab:Cd", "AbCd", "ab_cd")
  end

  # TODO -- test no namespace

  def test_bug_indexed_child_same_pid_added_twice
    element = Element.new
    attr0 = element.new_attribute("repeated")

    assert_equal(1, element.attribute_map.size)
    assert_equal(1, element.attribute_child.size)
    assert_equal(1, element.children.size)
    assert_equal(attr0, element.children[0])

    ce1 = element.new_child_element("something")

    assert_equal(1, element.attribute_map.size)
    assert_equal(1, element.attribute_child.size)
    assert_equal(2, element.children.size)
    assert_equal(attr0, element.children[0])
    assert_equal(ce1, element.children[1])

    attr2 = element.new_attribute("repeated")

    assert_equal(1, element.attribute_map.size)
    assert_equal(1, element.attribute_child.size)
    assert_equal(2, element.children.size)
    assert_equal(ce1, element.children[0])
    assert_equal(attr2, element.children[1])
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

