#!/usr/bin/env ruby -w

require "test/unit"
require "xamplr-generator"

include XamplGenerator
include Xampl

def assert_xampl_exception(name)
  xampl_exception = assert_raise(XamplException){
    yield
  }
  assert_equal(name, xampl_exception.name)
end

options = Xampl.make(Options) { | options |
  options.new_index_attribute("name")
  options.new_index_attribute("id")
  options.new_index_attribute("pid").persisted = true

  options.resolve("http://xampl.com/example", "XamplExample", "ex")
  options.resolve("http://xampl.com/example/special", "XamplExampleSpecial", "exs")
}
generator = Generator.new(options)

the_xml_file = File.join(".", "xml", "example.xml")
if (0 < ARGV.size) then
  File.open(the_xml_file){ | f |
    s = f.read
    generator.comprehend_from_strings([s])
    generator.generate_and_eval() { | module_definition, name |
      eval(module_definition, nil, name, 1)
    }

  #generator.print_stats
  }
  include XamplExample
else
  generator.comprehend_from_files([the_xml_file])
  generator.generate_to_directory(File.join(".", "tmp"))
  #generator.print_stats

  require "tmp/XamplExample"
  include XamplExample
end

#generator.report_elements

class TestXampl < Test::Unit::TestCase

  def setup
    Xampl.disable_all_persisters
    #FromXML.reset_registry
  end

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

    assert_equal("<ex:emph xmlns:ex='http://xampl.com/example'>emph 1</ex:emph>", emph1.test_to_xml)
    assert_equal("<ex:emph xmlns:ex='http://xampl.com/example'>emph 2</ex:emph>", emph2.test_to_xml)
    assert_equal("<ex:emph xmlns:ex='http://xampl.com/example'/>", emph3.test_to_xml)

    fakeRules = XMLPrinter.new("fake...")
    emph1.test_to_xml_internal(fakeRules)
    r = fakeRules.done

    assert_equal("fake... xmlns:ex='http://xampl.com/example'<ex:emph>emph 1</ex:emph>", r)

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

    assert_equal("<ex:stuff kind='test' xmlns:ex='http://xampl.com/example' xmlns:exs='http://xampl.com/example/special'/>",
                 stuff1.test_to_xml)
    assert_equal("<ex:stuff xmlns:ex='http://xampl.com/example' xmlns:exs='http://xampl.com/example/special'/>",
                 stuff2.test_to_xml)
    assert_equal("<ex:stuff kind='test' exs:special='test' xmlns:ex='http://xampl.com/example' xmlns:exs='http://xampl.com/example/special'/>",
                 stuff3.test_to_xml)

    fakeRules = XMLPrinter.new("fake...")
    stuff1.test_to_xml_internal(fakeRules)
    r = fakeRules.done
    assert_equal("fake... xmlns:ex='http://xampl.com/example' xmlns:exs='http://xampl.com/example/special'<ex:stuff kind='test'/>", r)

    check_parents(stuff1)
    check_parents(stuff2)
    check_parents(stuff3)
  end

  def test_mixed_xampl
    desc1 = Description.new
    assert_not_nil(desc1.is_changed)
    desc1.kind = "desc1"
    assert_not_nil(desc1.is_changed)
    assert_equal("<ex:description kind='desc1' xmlns:ex='http://xampl.com/example'/>",
                 desc1.test_to_xml)

    desc1.add_content("hello ")
    emph_content_1 = "there"
    desc1.new_emph.content = emph_content_1
    desc1.add_content("! How ")
    emph_content_2 = "are"
    desc1.new_emph.content = emph_content_2
    desc1.add_content(" you?")

    assert_not_nil(desc1.is_changed)
    assert_equal("<ex:description kind='desc1' xmlns:ex='http://xampl.com/example'>hello <ex:emph>there</ex:emph>! How <ex:emph>are</ex:emph> you?</ex:description>",
                 desc1.test_to_xml)
    assert_equal(desc1.emph_child.length, 2)
    assert_equal(emph_content_1, desc1.emph_child[0].content, emph_content_1)
    assert_equal(emph_content_2, desc1.emph_child[1].content, emph_content_2)

    check_parents(desc1)
  end

  def test_data_xampl
    emph_content_1 = "there"
    emph_content_2 = "are"
    big_thing = Xampl.make(Thing){ | big_thing |
      big_thing.pid = "big_thing"
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
    ###    emph_content_1 = "there"
    ###    desc1.new_emph.content = emph_content_1
    ###    desc1.add_content("! How ")
    ###    emph_content_2 = "are"
    ###    desc1.new_emph.content = emph_content_2
    ###    desc1.add_content(" you?")
    ###
    ###    thing = Thing.new
    ###    thing.pid = "thing"
    ###    assert(thing.is_changed)
    ###    thing.new_stuff.kind = "stuff1"
    ###    assert_not_nil(thing.is_changed)
    ###    thing.is_changed = nil
    ###    thing.add_description(desc1)
    ###    assert_not_nil(thing.is_changed)
    ###
    ###    big_thing = Thing.new
    ###    big_thing.add_thing(thing)
    assert_equal("<ex:thing pid='big_thing' xmlns:ex='http://xampl.com/example' xmlns:exs='http://xampl.com/example/special'><ex:thing pid='thing'><ex:stuff kind='stuff1'/><ex:description kind='desc1'>hello <ex:emph>there</ex:emph>! How <ex:emph>are</ex:emph> you?</ex:description></ex:thing></ex:thing>",
                 big_thing.test_to_xml)

    assert_equal(1, big_thing.children.length)
    assert_equal(2, big_thing.thing_child[0].children.length)
    assert_equal(big_thing.thing_child[0].description_child[0].emph_child.length, 2)
    assert_equal(emph_content_1, big_thing.thing_child[0].description_child[0].emph_child[0].content, emph_content_1)
    assert_equal(emph_content_2, big_thing.thing_child[0].description_child[0].emph_child[1].content, emph_content_2)

    check_parents(big_thing)
  end

  def test_ensure
    big_thing = Xampl.make(Thing){ | big_thing |
      big_thing.pid = "big_thing"
      big_thing.ensure_thing("thing"){ | thing |
        thing.info = "first";
      }
      big_thing.ensure_thing("thing"){ | thing |
        flunk "What are you doing in here?"
        thing.info = "second";
      }
    }

    assert_equal(1, big_thing.thing.length)
    assert_equal("first", big_thing.thing[0].info)

    desc = Description.new
    desc.ensure_emph
    assert_equal(1, desc.emph.length)
    #NOTE -- ensure_emph used to be aliased to new_emph, now it just makes
    #        sure that there is at least one emph
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

    assert_equal("<ex:thing xmlns:ex='http://xampl.com/example' xmlns:exs='http://xampl.com/example/special'><ex:thing pid='thing'><ex:stuff kind='stuff1'/><ex:description kind='desc1'>hello <ex:emph>there</ex:emph>! How <ex:emph>are</ex:emph> you?</ex:description></ex:thing></ex:thing>",
                 big_thing.test_to_xml)

    assert_equal(2, big_thing.thing_child[0].description_child[0].emph_child.length)
    assert_equal(emph_content_1, big_thing.thing_child[0].description_child[0].emph_child[0].content)
    assert_equal(emph_content_2, big_thing.thing_child[0].description_child[0].emph_child[1].content)

    check_parents(big_thing)
  end

  def test_yaml_round_trip
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

    big_thing = Thing.new("big_thing")
    big_thing << "leading content" << thing << "trailing content"

    check_parents(big_thing)

    #puts YAML::dump(big_thing)
    #puts big_thing.test_to_xml

    #something = XamplObject.from_yaml(YAML::dump(big_thing))
    pp_xml = big_thing.pp_xml
    bt_as_yaml = big_thing.as_yaml

    something = XamplObject.from_yaml(bt_as_yaml)

    assert_not_same(something, big_thing)
    assert_equal(something.test_to_xml, big_thing.persist)
    check_parents(something)

    something = XamplObject.from_yaml(big_thing.as_yaml)
    assert_equal(something.test_to_xml, big_thing.persist)
    assert_not_same(something, big_thing)
    check_parents(something)
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

    #puts big_thing.test_to_xml
    #pp = FromXML.new
    #pp.setup_parse_string(big_thing.test_to_xml)
    #while not pp.endDocument?
    #event = pp.next_interesting_event
    #puts event
    #if (event == Xampl_PP::TEXT) then
    #puts "TEXT [[[" << pp.text << "]]]"
    #end
    #end

    pp = FromXML.new
    pp.setup_parse_string(big_thing.test_to_xml)
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
    #another_big_thing = pp.parse_string(big_thing.test_to_xml)
    another_big_thing = pp.parse_string(big_thing.pp_xml)

    #assert_equal(big_thing.test_to_xml, another_big_thing.test_to_xml)
    assert_equal(big_thing.pp_xml.gsub(/\s/, ''), another_big_thing.pp_xml.gsub(/\s/, ''))
    assert_not_same(big_thing, another_big_thing)
  end

  def test_index
    thing = Thing.new
    thing.new_key_value("one").value = "1"
    thing.new_key_value("two").value = "2"

    assert_same(thing.key_value_child[0], thing.key_value_child["one"])
    assert_same(thing.key_value_child[1], thing.key_value_child["two"])

    thing.new_key_value("one").value = "1a"

    assert_same(thing.key_value_child[0], thing.key_value_child["two"])
    assert_same(thing.key_value_child[1], thing.key_value_child["one"])

    check_parents(thing)
  end

  def test_indexed_remove
    thing = Thing.new
    thing.new_key_value("one").value = "1"
    thing.remove_key_value(thing.key_value["one"])

    assert_equal(0, thing.children.size)
    assert_equal(0, thing.key_value_child.size)

    thing = Thing.new
    thing.new_key_value("one").value = "1"
    thing.new_key_value("two").value = "2"
    thing.remove_key_value(thing.key_value["one"])

    assert_equal(1, thing.children.size)
    assert_equal(1, thing.key_value_child.size)
    assert_not_nil(thing.key_value["two"])
    assert_equal("2", thing.key_value["two"].value)

  end

  def test_parents
    thing = Thing.new
    (kv1 = thing.new_key_value("one")).value = "1"
    (kv2 = thing.new_key_value("two")).value = "2"

    assert_same(thing, thing.key_value_child[0].parents[0])
    assert_same(thing, thing.key_value_child[1].parents[0])

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
    assert_equal("<ex:stuff kind='123.456' xmlns:ex='http://xampl.com/example' xmlns:exs='http://xampl.com/example/special'/>",
                 stuff1.test_to_xml)

    stuff1.kind = nil
    assert_equal("<ex:stuff xmlns:ex='http://xampl.com/example' xmlns:exs='http://xampl.com/example/special'/>",
                 stuff1.test_to_xml)

    stuff1.kind = [1, 2, 3]
    assert_equal("<ex:stuff kind='123' xmlns:ex='http://xampl.com/example' xmlns:exs='http://xampl.com/example/special'/>",
                 stuff1.test_to_xml)

    stuff2 = Stuff.new
    stuff2.kind = 123
    stuff1.kind = stuff2
    assert_equal("<ex:stuff kind='&lt;ex:stuff kind=&apos;123&apos; xmlns:ex=&apos;http://xampl.com/example&apos; xmlns:exs=&apos;http://xampl.com/example/special&apos;/&gt;' xmlns:ex='http://xampl.com/example' xmlns:exs='http://xampl.com/example/special'/>",
                 stuff1.test_to_xml)

    thing = Thing.new
    thing.pid = "thing"
    thing << stuff2
    stuff1.kind = thing
    assert_equal("<ex:stuff kind='&lt;ex:thing pid=&apos;thing&apos; xmlns:ex=&apos;http://xampl.com/example&apos; xmlns:exs=&apos;http://xampl.com/example/special&apos;&gt;&lt;ex:stuff kind=&apos;123&apos;/&gt;&lt;/ex:thing&gt;' xmlns:ex='http://xampl.com/example' xmlns:exs='http://xampl.com/example/special'/>",
                 stuff1.test_to_xml)

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

    assert_xampl_exception(:no_index_so_no_persist){
      persister.write(thing)
    }

    thing.pid = "thing"

    assert(persister.write(thing))

    saved_thing = persister.read(Thing, "thing")
    assert(saved_thing)

    assert_equal(thing.test_to_xml, saved_thing.test_to_xml)
    assert_not_same(thing, saved_thing)

    pname = "first" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    Xampl.enable_persister(pname, :in_memory)
    persister1 = Xampl.persister

    #check that the naming and kind checking is working
    assert_raise(IncompatiblePersisterRequest){
      Xampl.enable_persister(pname, :filesystem)
    }
    #okay, carry on

    Xampl.enable_persister(pname, :in_memory)
    persister2 = Xampl.persister

    assert_equal(persister1, persister2)

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
    assert_same(thing, Xampl.lookup(Thing, "thing"), "cannot lookup new stuff")
    assert_same(thing, Thing.lookup("thing"), "cannot lookup new stuff")
    assert_same(thing, Thing["thing"], "cannot lookup new stuff")

    #Xampl.print_stats

    assert_equal(1, Xampl.count_changed)
    writes = Xampl.sync
    assert_equal(1, writes)
    assert_equal(0, Xampl.count_changed)
    assert(Xampl.lookup(Thing, "thing"))

    assert_same(thing, Xampl.lookup(Thing, "thing"), "cannot lookup cached stuff")

    Xampl.clear_cache

    found = Xampl.lookup(Thing, "thing")
    assert_not_equal(thing, found)
    assert(thing === found)

    #Xampl.print_stats
  end

  def test_in_memory_persistence_ruby
    pname = "test_in_memory_persistence_ruby" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    Xampl.enable_persister(pname, :in_memory, :ruby_format)
    persister2 = Xampl.persister

    stuff = Stuff.new
    thing = Thing.new
    thing.pid = "thing"
    thing << stuff

    Xampl.introduce_to_persister(thing)
    Xampl.sync
    Xampl.clear_cache
    found = Xampl.lookup(Thing, "thing")

    assert_not_equal(thing, found)
    assert(thing === found)
  end

  def test_in_memory_persistence_yaml
    pname = "test_in_memory_persistence_yaml" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    Xampl.enable_persister(pname, :in_memory, :yaml_format)
    persister2 = Xampl.persister

    stuff = Stuff.new
    thing = Thing.new
    thing.pid = "thing"
    thing << stuff

    Xampl.introduce_to_persister(thing)
    Xampl.sync
    Xampl.clear_cache
    found = Xampl.lookup(Thing, "thing")

    assert_not_equal(thing, found)
    assert(thing === found)
  end

  def test_in_memory_persistence_rollback
    pname = "first" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    original_persister = Xampl.enable_persister(pname, :in_memory)

    stuff = Stuff.new
    thing = Thing.new
    thing.pid = "thing"
    thing << stuff

    Xampl.introduce_to_persister(thing)

    Xampl.rollback

    current_persister = Xampl.persister

    #assert_not_equal(original_persister, current_persister)
    assert_equal(original_persister, current_persister)

    # no sync after thing's creation, so thing should NOT exist after rollback
    found = Xampl.lookup(Thing, "thing")
    assert_nil(found)

    assert_equal(original_persister, thing.persister)

    #assert_xampl_exception(:live_across_rollback){
    #  thing.new_stuff
    #}
    assert_raise(XamplIsInvalid){
      thing.new_stuff
    }

    writes = Xampl.sync

    assert_equal(0, writes)
  end

  def test_in_memory_persistence_rollback_survival
    pname = "first" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    original_persister = Xampl.enable_persister(pname, :in_memory)

    stuff = Stuff.new
    thing = Thing.new
    thing.pid = "thing"
    thing << stuff

    Xampl.introduce_to_persister(thing)

    Xampl.sync

    thing.new_stuff
    thing.info = "something"

    Xampl.rollback

    assert(thing.load_needed)
    assert(!thing.is_changed)

    assert_nil(thing.info, "attributes not cleared by the rollback")

    current_persister = Xampl.persister

    #assert_not_equal(original_persister, current_persister)
    assert_equal(original_persister, current_persister) # stomp

    # a sync done BEFORE the second 'stuff' was added to thing
    found = Xampl.lookup(Thing, "thing")
    assert_equal(thing, found)

    assert_equal(original_persister, current_persister)
    assert_equal(original_persister, thing.persister)
    assert_equal(current_persister, found.persister)

    assert_equal(1, thing.stuff.size)
    assert_equal(1, found.stuff.size)

    #    assert_xampl_exception(:live_across_rollback){
    #      thing.new_stuff
    #    }

    writes = Xampl.sync

    assert_equal(0, writes)

    new_thing = found.new_thing("new_thing")
    new_thing.new_stuff

    writes = Xampl.sync

    assert_equal(2, writes)

    new_thing.new_stuff
    writes = Xampl.sync
    assert_equal(1, writes)
  end

  def test_filesystem_persistence_basics
    stuff = Stuff.new
    thing = Thing.new
    thing << stuff

    thing.pid = "thing"

    assert_xampl_exception(:name_required){
      Xampl.enable_persister(nil, :filesystem)
    }

    pname = "test_filesystem_persistence_basics_ut" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    Xampl.enable_persister(pname, :filesystem)

    stuff = Stuff.new
    thing = Thing.new
    thing.pid = "thing"
    thing << stuff

    assert_nil(Xampl.lookup(Thing, "thing"))

    assert(nil == thing.persister)
    assert(thing.is_changed)
    assert_equal(0, Xampl.count_changed)

    Xampl.introduce_to_persister(thing)

    assert(thing.persister)
    assert_equal(1, Xampl.count_changed)
    assert_same(thing, Xampl.lookup(Thing, "thing"), "cannot lookup new stuff")

    #Xampl.print_stats

    assert_equal(1, Xampl.count_changed)
    writes = Xampl.sync
    assert_equal(1, writes)
    assert_equal(0, Xampl.count_changed)
    assert(Xampl.lookup(Thing, "thing"))

    assert_same(thing, Xampl.lookup(Thing, "thing"), "cannot lookup cached stuff")

    Xampl.clear_cache

    found = Xampl.lookup(Thing, "thing")
    assert_not_same(thing, found)
    assert(thing === found)

    Xampl.clear_cache

    # now, changing thing will affect the DB -- VERY SUBTLE POSSIBLIITY OF BUG!
    thing.new_stuff
    assert_equal(2, thing.stuff.size)
    assert_equal(1, found.stuff.size)

    writes = Xampl.sync

    assert_equal(2, thing.stuff.size)
    assert_equal(1, found.stuff.size)

    found2 = Xampl.lookup(Thing, "thing")

    assert_equal(2, thing.stuff.size)
    assert_equal(1, found.stuff.size)
    assert_equal(2, found2.stuff.size)

    assert(!(found === found2))
    assert(thing === found2)

    assert_not_equal(found, found2)

    #Xampl.print_stats
  end

  def test_filesystem_persistence_very_many
    name = "test_filesystem_persistence_very_many_ut" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    holder = nil

    Xampl.transaction(name, :filesystem, automatic=true) do
      holder = Thing.new("root")
    end

    1.upto(200) do |i|
      Xampl.transaction(name, :filesystem, automatic=true) do
        child = holder.new_thing("child#{i}")
      end
    end

    #Xampl.transaction(name, :filesystem, automatic=true) do
    #Xampl.print_stats
    #end

    Xampl.transaction(name, :filesystem, automatic=true) do
      holder.thing.each{ | child |
        found = Xampl.lookup(Thing, child.pid)
        assert_equal(child, found)
      }
      #Xampl.print_stats
    end
  end

  def test_filesystem_persistence_over_write_on_parse
    name = "test_filesystem_persistence_over_write_on_parse_ut" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    holder = nil
    Xampl.transaction(name, :filesystem, automatic=true) do
      holder = Thing.new("root")
    end

    Xampl.transaction(name, :filesystem, automatic=true) do
      1.upto(10) do |i|
        cname = "child#{i}"
        child = holder.new_thing(cname)
        child.new_key_value('index').value = cname
      end
    end

    Xampl.transaction(name, :filesystem, automatic=true) do
      Xampl.print_stats
    end

    xml = holder.pp_xml

    Xampl.transaction(name, :filesystem, automatic=true) do
      1.upto(11) do |i|
        cname = "child#{i}"
        child = holder.ensure_thing(cname)
        child.ensure_key_value('index').value = "changed#{i}"
      end
      holder.remove_thing("child1")
    end

    assert_equal(10, holder.thing.size)
    assert_equal(holder.children.size, holder.thing.size)

    parsed_holder = nil
    Xampl.transaction(name, :filesystem, automatic=true) do
      parsed_holder = XamplObject.from_xml_string(xml)
    end

    assert_equal(10, holder.thing.size)
    assert_equal(holder.children.size, holder.thing.size)

    assert_equal(parsed_holder, holder)

    Xampl.transaction(name, :filesystem, automatic=true) do
      holder.thing.each{ | child |
        found = Xampl.lookup(Thing, child.pid)
        assert_equal(child, found)
        assert_equal(child, parsed_holder.thing[child.pid])
      }
      Xampl.print_stats
    end
  end

  def test_filesystem_persistence_ruby
    pname = "test_filesystem_persistence_ruby" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    Xampl.enable_persister(pname, :filesystem, :ruby_format)
    persister2 = Xampl.persister

    stuff = Stuff.new
    thing = Thing.new
    thing.pid = "thing"
    thing << stuff

    Xampl.introduce_to_persister(thing)
    Xampl.sync

    thing.info = "force emptying"

    Xampl.rollback

    assert(thing.load_needed)

    found = Xampl.lookup(Thing, "thing")

    assert_equal(thing.object_id, found.object_id)
  end

  def test_filesystem_persistence_yaml
    pname = "test_filesystem_persistence_yaml" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    Xampl.enable_persister(pname, :filesystem, :yaml_format)
    persister2 = Xampl.persister

    stuff = Stuff.new
    thing = Thing.new
    thing.pid = "thing"
    thing << stuff

    Xampl.introduce_to_persister(thing)
    Xampl.sync

    thing.info = "force emptying"

    Xampl.rollback

    assert(thing.load_needed)

    found = Xampl.lookup(Thing, "thing")

    assert_equal(thing.object_id, found.object_id)
  end

  def test_filesystem_persistence_automatic
    stuff = Stuff.new
    thing = Thing.new
    thing << stuff

    thing.pid = "thing"

    pname = "test_filesystem_persistence_automatic_ut" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    Xampl.enable_persister(pname, :filesystem)
    Xampl.auto_persistence

    stuff = Stuff.new
    thing = Thing.new
    thing.pid = "thing"
    thing << stuff

    assert_equal(thing, Xampl.lookup(Thing, "thing"))

    assert(thing.persister)
    assert(thing.is_changed)
    assert_equal(1, Xampl.count_changed)

    assert_equal(thing, Xampl.lookup(Thing, "thing"), "cannot lookup new stuff")

    writes = Xampl.sync

    assert_equal(1, writes)
    assert_equal(0, Xampl.count_changed)

    assert(Xampl.lookup(Thing, "thing"))
    assert_equal(thing, Xampl.lookup(Thing, "thing"), "cannot lookup cached stuff")
    assert_same(thing, Xampl.lookup(Thing, "thing"), "cannot lookup cached stuff")

    Xampl.clear_cache

    found = Xampl.lookup(Thing, "thing")
    assert_not_equal(thing, found)
    assert_not_same(thing, found)

    root = Thing.new
    root.pid = "root"
    found2 = root.new_thing("thing")

    assert_equal(found, found2, "in automatic persistence mode, supposed to look stuff up")

    #Xampl.print_stats
  end

  def test_filesystem_persistence_rollback
    pname = "test_filesystem_persistence_rollback_ut" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    original_persister = Xampl.enable_persister(pname, :filesystem)

    stuff = Stuff.new
    thing = Thing.new
    thing.pid = "thing"
    thing << stuff

    Xampl.introduce_to_persister(thing)

    Xampl.rollback

    current_persister = Xampl.persister

    assert_equal(original_persister, current_persister)
    #assert_not_equal(original_persister, current_persister)

    # no sync after thing's creation, so thing should NOT exist after rollback
    found = Xampl.lookup(Thing, "thing")
    assert_nil(found)

    assert_equal(original_persister, thing.persister)

    #assert_xampl_exception(:live_across_rollback){
    #  thing.new_stuff
    #}
    thing.stuff.size

    writes = Xampl.sync

    assert_equal(0, writes)
  end

  def test_filesystem_persistence_rollback_survival
    pname = "test_filesystem_persistence_rollback_survival_ut" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    original_persister = Xampl.enable_persister(pname, :filesystem)

    stuff = Stuff.new
    thing = Thing.new
    thing.pid = "thing"
    thing << stuff

    Xampl.introduce_to_persister(thing)

    assert_equal(1, thing.stuff.size)
    Xampl.sync
    assert_equal(1, thing.stuff.size)

    thing.new_stuff
    thing.info = "something"

    assert_equal(2, thing.stuff.size)

    Xampl.rollback

    assert(thing.load_needed)
    assert_nil(thing.info, "attributes not cleared by the rollback")
    assert(!thing.load_needed)
    assert_equal(1, thing.stuff.size)

    current_persister = Xampl.persister

    assert_equal(original_persister, current_persister)

    # a sync done BEFORE the second 'stuff' was added to thing
    found = Xampl.lookup(Thing, "thing")
    assert_equal(found.object_id, thing.object_id)

    assert_equal(original_persister, current_persister)
    assert_equal(current_persister, thing.persister)
    assert_equal(current_persister, found.persister)

    assert(!thing.load_needed)
    assert(!thing.is_changed)

    thing.stuff.size

    assert(!thing.load_needed)
    assert(!thing.is_changed)

    assert_equal(found.object_id, thing.object_id)
    assert_equal(1, thing.stuff.size)
    assert_equal(1, found.stuff.size)

    #assert_xampl_exception(:live_across_rollback){
    #  thing.new_stuff
    #}

    assert(!thing.is_changed)
    writes = Xampl.sync

    assert_equal(0, writes)

    new_thing = found.new_thing("new_thing")
    new_thing.new_stuff

    writes = Xampl.sync

    assert_equal(2, writes)

    new_thing.new_stuff
    writes = Xampl.sync
    assert_equal(1, writes)

    Xampl.rollback

    assert_equal(0, Xampl.persister.read_count)

    thing = Thing.lookup("thing")
    assert_not_nil(thing)
    assert_equal(0, Xampl.persister.read_count, "not in the cache")

    new_thing = thing.thing["new_thing"]
    assert_not_nil(new_thing)
    assert_equal(0, Xampl.persister.read_count, "not in the cache")

    keep_new_thing = new_thing

    # these (to xml, ruby, yaml) will NOT suck the child thing into memory
    xml = thing.test_to_xml

    ruby = thing.to_ruby
    ruby_thing = XamplObject.from_ruby(ruby)
    yaml_thing = XamplObject.from_yaml(thing.as_yaml)

    assert_equal(0, Xampl.persister.read_count, "not in the cache")

    # this will trigger the lazy load of new_thing
    size = new_thing.stuff.size

    assert_equal(0, Xampl.persister.read_count, "not in the cache")
    assert_equal(keep_new_thing, new_thing)
    assert_equal(new_thing, thing.thing["new_thing"])

    Xampl.rollback

    # another way to get stuff into memory
    # ACTUALLY, this is not legal, there is a cache conflict problem
    illegal_lazy_thing = Thing.new
    illegal_lazy_thing.pid = "thing"
    illegal_lazy_thing.load_needed = true
    #assert_xampl_exception(:cache_conflict){
    #  assert(thing === illegal_lazy_thing)
    #}
    #assert_raise(XamplIsInvalid){
    #  # due to a change in xampl this is OK (it isn't invalid yet)
    #illegal_lazy_thing.info = "oops"
    #}

    okay_thing = Thing.lookup("thing")
    assert(okay_thing)
    okay_thing.info = "okay"
  end


  def test_escaping
    description = Description.new
    description.kind = "<>&'\""
    description << "<>&'\""

    expect = "<ex:description kind='&lt;&gt;&amp;&apos;&quot;' xmlns:ex='http://xampl.com/example'>&lt;>&amp;'\"</ex:description>"

    assert_equal(expect, description.test_to_xml)
  end

  def choose_name_test_helper(name, expected_class_name, expected_attribute_name)
    original_name = name.dup
    class_name, attribute_name = Generator.choose_names(name, "", "")
    assert_equal(original_name, name, "changed the original name")
    assert_equal(expected_class_name, class_name, "CLASS name wrong")
    assert_equal(expected_attribute_name, attribute_name, "ATTRIBUTE name wrong")
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
    element = elements.element_child[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(!element.empty)
    assert(element.has_content)

    ename = "description"
    element = elements.element_child[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(!element.empty)
    assert(element.has_content)

    assert_equal(1, element.attribute_child.size)
    assert_not_nil(element.attribute_child["kind"])
    assert_nil(element.attribute_child["kind"].namespace)

    assert_equal(1, element.child_element_child.size)
    cname = "{#{ns}}emph"
    assert_not_nil(element.child_element_child[cname])
    assert_equal(ns, element.child_element_child[cname].namespace)
    assert_equal("emph", element.child_element_child[cname].element_name)

    ename = "stuff"
    element = elements.element_child[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(element.empty)
    assert(!element.has_content)

    assert_equal(2, element.attribute_child.size)
    assert_not_nil(element.attribute_child["kind"])
    assert_nil(element.attribute_child["kind"].namespace)
    assert_not_nil(element.attribute_child["special"])
    assert_equal('http://xampl.com/example/special', element.attribute_child["special"].namespace)

    assert_equal(0, element.child_element_child.size)

    ename = "keyValue"
    element = elements.element_child[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(element.empty)
    assert(!element.has_content)

    assert_equal(2, element.attribute_child.size)
    assert_not_nil(element.attribute_child["id"])
    assert_nil(element.attribute_child["id"].namespace)
    assert_not_nil(element.attribute_child["value"])
    assert_nil(element.attribute_child["value"].namespace)

    assert_equal(0, element.child_element_child.size)

    ename = "thing"
    element = elements.element_child[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(element.empty)
    assert(!element.has_content)

    assert_equal(1, element.attribute_child.size)
    assert_equal(1, element.attribute_child.size)
    assert_not_nil(element.attribute_child["pid"])
    assert_nil(element.attribute_child["pid"].namespace)

    assert_equal(5, element.child_element_child.size)

    cname = "{#{ns}}description"
    assert_not_nil(element.child_element_child[cname])
    assert_equal(ns, element.child_element_child[cname].namespace)
    assert_equal("description", element.child_element_child[cname].element_name)

    cname = "{#{ns}}keyValue"
    assert_not_nil(element.child_element_child[cname])
    assert_equal(ns, element.child_element_child[cname].namespace)
    assert_equal("keyValue", element.child_element_child[cname].element_name)

    cname = "{#{ns}}stuff"
    assert_not_nil(element.child_element_child[cname])
    assert_equal(ns, element.child_element_child[cname].namespace)
    assert_equal("stuff", element.child_element_child[cname].element_name)

    cname = "{#{ns}}thing"
    assert_not_nil(element.child_element_child[cname])
    assert_equal(ns, element.child_element_child[cname].namespace)
    assert_equal("thing", element.child_element_child[cname].element_name)

    cname = "{#{ns}}things"
    assert_not_nil(element.child_element_child[cname])
    assert_equal(ns, element.child_element_child[cname].namespace)
    assert_equal("things", element.child_element_child[cname].element_name)

    ename = "things"
    element = elements.element_child[ename]
    assert_not_nil(element)
    assert_equal(ns, element.namespace)
    assert_equal("{#{ns}}#{ename}", element.nstag)
    assert(element.empty)
    assert(!element.has_content)

    assert_equal(0, element.attribute_child.size)
    assert_equal(1, element.child_element_child.size)

    cname = "{#{ns}}thing"
    assert_not_nil(element.child_element_child[cname])
    assert_equal(ns, element.child_element_child[cname].namespace)
    assert_equal("thing", element.child_element_child[cname].element_name)

    #generator.print_stats
    generator.analyse

    ename = "emph"
    element = elements.element_child[ename]
    assert_equal("simple", element.kind, "emph is wrong kind")
    assert_nil(element.indexed_by_attr)
    assert_nil(element.persisted)
    assert_equal("XamplAdHoc", element.package)
    assert_equal("Emph", element.class_name)
    assert_equal("emph", element.attribute_name)

    ename = "description"
    element = elements.element_child[ename]
    assert_equal("mixed", element.kind, "description is wrong kind")
    assert_nil(element.indexed_by_attr)
    assert_nil(element.persisted)
    assert_equal("XamplAdHoc", element.package)
    assert_equal("Description", element.class_name)
    assert_equal("description", element.attribute_name)

    ename = "stuff"
    element = elements.element_child[ename]
    assert_equal("empty", element.kind, "stuff is wrong kind")
    assert_nil(element.indexed_by_attr)
    assert_nil(element.persisted)
    assert_equal("XamplAdHoc", element.package)
    assert_equal("Stuff", element.class_name)
    assert_equal("stuff", element.attribute_name)

    ename = "keyValue"
    element = elements.element_child[ename]
    assert_equal("empty", element.kind, "keyValue is wrong kind")
    assert_equal("id", element.indexed_by_attr)
    assert_nil(element.persisted)
    assert_equal("XamplAdHoc", element.package)
    assert_equal("KeyValue", element.class_name)
    assert_equal("key_value", element.attribute_name)

    ename = "thing"
    element = elements.element_child[ename]
    assert_equal("data", element.kind, "thing is wrong kind")
    assert_equal("pid", element.indexed_by_attr)
    assert_not_nil(element.persisted)
    assert_equal("XamplAdHoc", element.package)
    assert_equal("Thing", element.class_name)
    assert_equal("thing", element.attribute_name)

    #generator.generate_to_directory(nil)
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

    choose_name_test_helper("ab.cd", "AbCd", "ab_cd")

    choose_name_test_helper("ab9cd", "AbCd", "ab_cd")
    choose_name_test_helper("ab9Cd", "AbCd", "ab_cd")
  end

  # TODO -- test no namespace

  def test_bug_indexed_child_same_pid_added_twice
    element = Element.new
    attr0 = element.new_attribute("repeated")

    assert_equal(1, element.attribute_child.size)
    assert_equal(1, element.attribute_child.size)
    assert_equal(1, element.children.size)
    assert_equal(attr0, element.children[0])

    ce1 = element.new_child_element("something")

    assert_equal(1, element.attribute_child.size)
    assert_equal(1, element.attribute_child.size)
    assert_equal(2, element.children.size)
    assert_equal(attr0, element.children[0])
    assert_equal(ce1, element.children[1])

    attr2 = element.new_attribute("repeated")

    assert_equal(1, element.attribute_child.size)
    assert_equal(1, element.attribute_child.size)
    assert_equal(2, element.children.size)
    assert_equal(ce1, element.children[0])
    assert_equal(attr2, element.children[1])
  end

  def test_cycles_and_bushy_lookup
    pname = "test_cycles_and_bushy" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    #Xampl.enable_persister(pname, :filesystem)
    Xampl.enable_persister(pname, :in_memory)
    Xampl.auto_persistence

    root = Thing.new("root")
    root.info = "one"

    root.new_thing("branch1").new_thing("leaf").info = "two"
    root.new_thing("branch2").new_thing("leaf").info = "three"
    root.new_thing("branch3").new_thing("leaf").info = "four"

    root.new_thing("cycle0").info = "five"
    Thing.lookup("cycle0").new_thing("cycle1").new_thing("cycle2").info = "six"
    Thing.lookup("cycle2").new_thing("cycle0")

    assert(Thing.lookup("cycle2").thing["cycle0"] == Thing.lookup("cycle0"))
    assert(Thing.lookup("root").thing["cycle0"] == Thing.lookup("cycle0"))

    Xampl.sync

    assert_equal(8, CountingVisitor.new.start(root).count)

    pp_xml = root.pp_xml
    #puts root.pp_xml
  end

  def test_cycles_and_bushy2_locals
    pname = "test_cycles_and_bushy" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    #Xampl.enable_persister(pname, :filesystem)
    Xampl.enable_persister(pname, :in_memory)
    Xampl.auto_persistence

    root = Thing.new("root")

    root.new_thing("branch1").new_thing("leaf")
    root.new_thing("branch2").new_thing("leaf")
    root.new_thing("branch3").new_thing("leaf")

    cycle0 = root.new_thing("cycle0")
    cycle0.new_thing("cycle1").new_thing("cycle2").new_thing("cycle0")

    assert_equal(Thing.lookup("cycle2").thing["cycle0"],
                 Thing.lookup("root").thing["cycle0"])

    Xampl.sync

    assert_equal(8, CountingVisitor.new.start(root).count)

    #puts root.pp_xml
  end

  def test_internal_cycles_and_bushy
    pname = "test_internal_cycles_and_bushy" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
    #Xampl.enable_persister(pname, :filesystem)
    Xampl.enable_persister(pname, :in_memory)
    Xampl.auto_persistence

    root = Thing.new("root")
    root.info = "root"

    (branch1 = Branch.new).info='one'
    (branch2 = Branch.new).info='two'
    (branch3 = Branch.new).info='three'
    (branch4 = Branch.new).info='four'
    (branch5 = Branch.new).info='five'

    #puts branch1.pp_xml

    #
    #                1
    #             2     3
    #                4
    #                1
    #        and 5 is a child of 1, 2, 3, and 4

    root << branch1

    branch1 << branch2
    branch1 << branch3

    branch2 << branch4
    branch3 << branch4

    branch4 << branch1

    branch1 << branch5
    branch2 << branch5
    branch3 << branch5
    branch4 << branch5

    #assert_xampl_exception(:cycle_detected_in_xampl_cluster){
    assert_xampl_exception(:cycle_detected_in_xampl_cluster){
      xml = PersistXML.new("").start(root).done
    }

    assert_xampl_exception(:cycle_detected_in_xampl_cluster){
      Xampl.sync
    }

    #there is one thing and 5 branches, so 6 different things
    assert_equal(6, CountingVisitor.new.start(root).count)

    pp_xml = root.pp_xml
  end

#  def test_fsdb_extension_persistence_basics
#    require 'persister/fsdb'
#    stuff = Stuff.new
#    thing = Thing.new
#    thing << stuff
#
#    thing.pid = "thing"
#
#    assert_xampl_exception(:name_required){
#      Xampl.enable_persister(nil, :fsdb)
#    }
#
#    pname = "test_fsdb_extension_persistence_basics" << Time.now.strftime("%Y%m%d-%H%M-%S") << rand.to_s
#    Xampl.enable_persister(pname, :fsdb)
#
#    stuff = Stuff.new
#    thing = Thing.new
#    thing.pid = "thing"
#    thing << stuff
#
#    assert_nil(Xampl.lookup(Thing, "thing"))
#
#    assert(nil == thing.persister)
#    assert(thing.is_changed)
#    assert_equal(0, Xampl.count_changed)
#
#    Xampl.introduce_to_persister(thing)
#
#    assert(thing.persister)
#    assert_equal(1, Xampl.count_changed)
#    assert_same(thing, Xampl.lookup(Thing, "thing"), "cannot lookup new stuff")
#
#    #Xampl.print_stats
#
#    assert_equal(1, Xampl.count_changed)
#    writes = Xampl.sync
#    assert_equal(1, writes)
#    assert_equal(0, Xampl.count_changed)
#    assert(Xampl.lookup(Thing, "thing"))
#
#    thing2 = Xampl.lookup(Thing, "thing")
#    assert_same(thing, thing2, "cannot lookup cached stuff")
#
#    Xampl.clear_cache
#
#    found = Xampl.lookup(Thing, "thing")
#    assert_not_same(thing, found)
#    assert(thing === found)
#
#    Xampl.clear_cache
#
#    # now, changing thing will affect the DB -- VERY SUBTLE POSSIBLIITY OF BUG!
#    thing.new_stuff
#    assert_equal(2, thing.stuff.size)
#    assert_equal(1, found.stuff.size)
#
#    writes = Xampl.sync
#
#    assert_equal(2, thing.stuff.size)
#    assert_equal(1, found.stuff.size)
#
#    found2 = Xampl.lookup(Thing, "thing")
#
#    assert_equal(2, thing.stuff.size)
#    assert_equal(1, found.stuff.size)
#    assert_equal(2, found2.stuff.size)
#
#    assert(!(found === found2))
#    assert(thing === found2)
#
#    assert_not_equal(found, found2)
#
#    #Xampl.print_stats
#  end

  def test_simple_extension_persistence_basics
    stuff = Stuff.new
    thing = Thing.new
    thing << stuff

    thing.pid = "thing"

    Xampl.enable_persister(nil, :simple)

    stuff = Stuff.new
    thing = Thing.new
    thing.pid = "thing"
    thing << stuff

    assert_nil(Xampl.lookup(Thing, "thing"))

    assert(nil == thing.persister)
    assert(thing.is_changed)
    assert_equal(0, Xampl.count_changed)

    Xampl.introduce_to_persister(thing)

    assert(thing.persister)
    assert_equal(0, Xampl.count_changed)
    assert_same(thing, Xampl.lookup(Thing, "thing"), "cannot lookup new stuff")

    #Xampl.print_stats

    assert_equal(0, Xampl.count_changed)
    writes = Xampl.sync
    assert_equal(0, Xampl.count_changed)
    assert(Xampl.lookup(Thing, "thing"))

    thing2 = Xampl.lookup(Thing, "thing")
    assert_same(thing, thing2, "cannot lookup cached stuff")

    found = Xampl.lookup(Thing, "thing")
    assert_equal(thing.object_id, found.object_id)

    #Xampl.print_stats
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

