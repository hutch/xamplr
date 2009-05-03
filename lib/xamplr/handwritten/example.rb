module XamplExample

  require "xamplr"

  module ThingsAsChild

    attr_accessor :things_child

    def init_things_as_child
      @things_child = []
    end

    def add_things(things)
      @children << things
      @things_child << things
      things.add_parent(self)
      changed
      return things
    end

    def new_things
      things = Things.new
      yield(things) if block_given?
      return add_things(things)
    end

    def remove_things(things)
      @things_child.delete(things)
      @children.delete(things)
    end
  end

  module ThingAsChild

    attr_accessor :thing_child, :thing_map

    def init_thing_as_child
      @thing_child = []
      @thing_map = {}
    end

    def add_thing(thing)
      index = thing.get_the_index
      if (nil == index) then
        throw "no index thing defined in : " << thing.to_xml
      end

      existing = @thing_map[index]
      remove_thing(existing) if existing

      @children << thing
      @thing_child << thing
      @thing_map[index] = thing
      thing.add_parent(self)
      changed
      return thing
    end

    def new_thing(index)
      thing = Thing.new
      thing.set_the_index(index)
      yield(thing) if block_given?
      return add_thing(thing)
    end

    def remove_thing(thing)
      index = thing.get_the_index
      if (nil == index) then
        throw "no index thing defined in : " << thing.to_xml
      end

      existing = @thing_map[index]
      if existing != thing then
        throw "will only remove the thing if it is already in the thing map"
      end

      @thing_map.delete(index)
      @thing_child.delete(thing)
      @children.delete(thing)
    end
  end

  module DescriptionAsChild

    attr_accessor :description_child

    def init_description_as_child
      @description_child = []
    end

    def add_description(description)
      @children << description
      @description_child << description
      description.add_parent(self)
      changed
      return description
    end

    def new_description
      description = Description.new
      yield(description) if block_given?
      return add_description(description)
    end

    def remove_description(description)
      @description_child.delete(description)
      @children.delete(description)
    end
  end

  module EmphAsChild

    attr_accessor :emph_child

    def init_emph_as_child
      @emph_child = []
    end

    def add_emph(emph)
      @children << emph
      @emph_child << emph
      emph.add_parent(self)
      changed
      return emph
    end

    def new_emph
      emph = Emph.new
      yield(emph) if block_given?
      return add_emph(emph)
    end

    def remove_emph(emph)
      @emph_child.delete(emph)
      @children.delete(emph)
    end
  end

  module KeyValueAsChild

    attr_accessor :key_value_child, :key_value_map

    def init_key_value_as_child
      @key_value_child = []
      @key_value_map = {}
    end

    def add_key_value(key_value)
      index = key_value.get_the_index
      if (nil == index) then
        throw "no index key_value defined in : " << key_value.to_xml
      end

      existing = @key_value_map[index]
      remove_key_value(existing) if existing

      @children << key_value
      @key_value_child << key_value
      @key_value_map[index] = key_value
      key_value.add_parent(self)
      changed
      return key_value
    end

    def new_key_value(index)
      key_value = KeyValue.new
      key_value.set_the_index(index)
      yield(key_value) if block_given?
      return add_key_value(key_value)
    end

    def remove_key_value(key_value)
      index = key_value.get_the_index
      if (nil == index) then
        throw "no index key_value defined in : " << key_value.to_xml
      end

      existing = @key_value_map[index]
      if existing != key_value then
        throw "will only remove the key_value if it is already in the key_value map"
      end

      @key_value_map.delete(index)
      @key_value_child.delete(key_value)
      @children.delete(key_value)
    end
  end

  module StuffAsChild

    attr_accessor :stuff_child

    def init_stuff_as_child
      @stuff_child = []
    end

    def add_stuff(stuff)
      @children << stuff
      @stuff_child << stuff
      stuff.add_parent(self)
      changed
      return stuff
    end

    def new_stuff
      stuff = Stuff.new
      yield(stuff) if block_given?
      return add_stuff(stuff)
    end

    def remove_stuff(stuff)
      @stuff_child.delete(stuff)
      @children.delete(stuff)
    end
  end


  class Things
    include Xampl::XamplPersistedObject
    include Xampl::XamplWithDataContent

    @@tag = "things"
    @@ns = "http://xampl.com/example"
    @@ns_tag = "{http://xampl.com/example}things"
    @@module_name = "XamplExample"
    @@attributes = [
            ]

    include ThingAsChild

    def Things.tag
      @@tag
    end

    def Things.ns
      @@ns
    end

    def Things.ns_tag
      @@ns_tag
    end

    def Things.module_name
      @@module_name
    end

    Xampl::FromXML::register(Things::tag, Things::ns_tag, Things)


    def initialize
      super
      init_xampl_object


      init_data_content

      init_thing_as_child

      yield(self) if block_given?
      changed
    end

    def append_to(other)
      other.add_things(self)
    end

    def tag
      @@tag
    end

    def ns
      @@ns
    end

    def ns_tag
      @@ns_tag
    end

    def module_name
      @@module_name
    end

    def attributes
      @@attributes
    end
  end

  class Thing
    include Xampl::XamplPersistedObject
    include Xampl::XamplWithDataContent

    @@tag = "thing"
    @@ns = "http://xampl.com/example"
    @@ns_tag = "{http://xampl.com/example}thing"
    @@module_name = "XamplExample"
    @@attributes = [
            [ :@pid, "pid" ],
    ]

    include DescriptionAsChild
    include KeyValueAsChild
    include StuffAsChild
    include ThingAsChild
    include ThingsAsChild

    attr_reader :pid

    def Thing.tag
      @@tag
    end

    def Thing.ns
      @@ns
    end

    def Thing.ns_tag
      @@ns_tag
    end

    def Thing.module_name
      @@module_name
    end

    Xampl::FromXML::register(Thing::tag, Thing::ns_tag, Thing)

    def pid=(v)
      changed
      @pid = v
    end

    def initialize
      super
      init_xampl_object

      @pid = nil if not defined? @pid

      init_data_content

      init_description_as_child
      init_key_value_as_child
      init_stuff_as_child
      init_thing_as_child
      init_things_as_child

      yield(self) if block_given?
      changed
    end

    def append_to(other)
      other.add_thing(self)
    end

    def tag
      @@tag
    end

    def ns
      @@ns
    end

    def ns_tag
      @@ns_tag
    end

    def module_name
      @@module_name
    end

    def attributes
      @@attributes
    end

    def get_the_index
      @pid
    end

    def set_the_index(index)
      @pid = index
    end
  end

  class Description
    include Xampl::XamplObject
    include Xampl::XamplWithMixedContent

    @@tag = "description"
    @@ns = "http://xampl.com/example"
    @@ns_tag = "{http://xampl.com/example}description"
    @@module_name = "XamplExample"
    @@attributes = [
            [ :@kind, "kind" ],
    ]

    include EmphAsChild

    attr_reader :kind

    def Description.tag
      @@tag
    end

    def Description.ns
      @@ns
    end

    def Description.ns_tag
      @@ns_tag
    end

    def Description.module_name
      @@module_name
    end

    Xampl::FromXML::register(Description::tag, Description::ns_tag, Description)

    def kind=(v)
      changed
      @kind = v
    end

    def initialize
      super
      init_xampl_object

      @kind = nil if not defined? @kind

      init_mixed_content

      init_emph_as_child

      yield(self) if block_given?
      changed
    end

    def append_to(other)
      other.add_description(self)
    end

    def tag
      @@tag
    end

    def ns
      @@ns
    end

    def ns_tag
      @@ns_tag
    end

    def module_name
      @@module_name
    end

    def attributes
      @@attributes
    end
  end

  class Emph
    include Xampl::XamplObject
    include Xampl::XamplWithSimpleContent

    @@tag = "emph"
    @@ns = "http://xampl.com/example"
    @@ns_tag = "{http://xampl.com/example}emph"
    @@module_name = "XamplExample"
    @@attributes = [
            ]


    def Emph.tag
      @@tag
    end

    def Emph.ns
      @@ns
    end

    def Emph.ns_tag
      @@ns_tag
    end

    def Emph.module_name
      @@module_name
    end

    Xampl::FromXML::register(Emph::tag, Emph::ns_tag, Emph)


    def initialize
      super
      init_xampl_object



      yield(self) if block_given?
      changed
    end

    def append_to(other)
      other.add_emph(self)
    end

    def tag
      @@tag
    end

    def ns
      @@ns
    end

    def ns_tag
      @@ns_tag
    end

    def module_name
      @@module_name
    end

    def attributes
      @@attributes
    end
  end

  class KeyValue
    include Xampl::XamplObject
    include Xampl::XamplWithoutContent

    @@tag = "keyValue"
    @@ns = "http://xampl.com/example"
    @@ns_tag = "{http://xampl.com/example}keyValue"
    @@module_name = "XamplExample"
    @@attributes = [
            [ :@id, "id" ],
                    [ :@value, "value" ],
    ]


    attr_reader :id
    attr_reader :value

    def KeyValue.tag
      @@tag
    end

    def KeyValue.ns
      @@ns
    end

    def KeyValue.ns_tag
      @@ns_tag
    end

    def KeyValue.module_name
      @@module_name
    end

    Xampl::FromXML::register(KeyValue::tag, KeyValue::ns_tag, KeyValue)

    def id=(v)
      changed
      @id = v
    end

    def value=(v)
      changed
      @value = v
    end

    def initialize
      super
      init_xampl_object

      @id = nil if not defined? @id
      @value = nil if not defined? @value


      yield(self) if block_given?
      changed
    end

    def append_to(other)
      other.add_key_value(self)
    end

    def tag
      @@tag
    end

    def ns
      @@ns
    end

    def ns_tag
      @@ns_tag
    end

    def module_name
      @@module_name
    end

    def attributes
      @@attributes
    end

    def get_the_index
      @id
    end

    def set_the_index(index)
      @id = index
    end
  end

  class Stuff
    include Xampl::XamplObject
    include Xampl::XamplWithoutContent

    @@tag = "stuff"
    @@ns = "http://xampl.com/example"
    @@ns_tag = "{http://xampl.com/example}stuff"
    @@module_name = "XamplExample"
    @@attributes = [
            [ :@kind, "kind" ],
                    [ :@special, "special", "http://xampl.com/example/special" ],
    ]


    attr_reader :kind
    attr_reader :special

    def Stuff.tag
      @@tag
    end

    def Stuff.ns
      @@ns
    end

    def Stuff.ns_tag
      @@ns_tag
    end

    def Stuff.module_name
      @@module_name
    end

    Xampl::FromXML::register(Stuff::tag, Stuff::ns_tag, Stuff)

    def kind=(v)
      changed
      @kind = v
    end

    def special=(v)
      changed
      @special = v
    end

    def initialize
      super
      init_xampl_object

      @kind = nil if not defined? @kind
      @special = nil if not defined? @special


      yield(self) if block_given?
      changed
    end

    def append_to(other)
      other.add_stuff(self)
    end

    def tag
      @@tag
    end

    def ns
      @@ns
    end

    def ns_tag
      @@ns_tag
    end

    def module_name
      @@module_name
    end

    def attributes
      @@attributes
    end
  end

end
