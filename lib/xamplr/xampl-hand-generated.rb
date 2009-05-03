module XamplGenerator

  require "xamplr"
  include Xampl

  XamplObject.ns_preferred_prefix("http://xampl.com/generator", "gen")

  module ElementsAsChild
    require "xamplr/indexed-array"

    def elements_child
      accessed
      @elements_child
    end

    def elements_child=(v)
      accessed
      @elements_child = v
    end

    alias elements elements_child
    alias elements= elements_child=

    def init_elements_as_child
      @elements_child = IndexedArray.new
    end

    def add_elements(elements)
      accessed
      index = elements.get_the_index
      if (nil == index) then
        throw "no value for the index 'pid' of elements defined in : " << elements.pp_xml
      end

      existing = @elements_child[index]

      self.remove_elements(index) if existing and (existing != elements)

      @children << elements
      @elements_child[index] = elements

      elements.add_parent(self)

      changed
      return elements
    end

    def new_elements(index)
      accessed

      elements = nil
      elements = Elements.lookup(index) if Xampl.persister and Xampl.persister.automatic
      elements = Elements.new(index) unless elements

      yield(elements) if block_given?
      return add_elements(elements)
    end

    def ensure_elements(index)
      accessed

      elements = @elements_child[index]
      return elements if elements

      elements = Elements.lookup(index) if Xampl.persister and Xampl.persister.automatic
      elements = Elements.new(index) unless elements

      yield(elements) if block_given?
      return add_elements(elements)
    end

    def remove_elements(index)
      accessed
      changed
      unless String === index or Symbol === index then
        index = index.get_the_index
      end
      elements = @elements_child.delete(index) if index
      @children.delete(elements)
    end
  end

  module ElementAsChild
    require "xamplr/indexed-array"

    def element_child
      accessed
      @element_child
    end

    def element_child=(v)
      accessed
      @element_child = v
    end

    alias element element_child
    alias element= element_child=

    def init_element_as_child
      @element_child = IndexedArray.new
    end

    def add_element(element)
      accessed
      index = element.get_the_index
      if (nil == index) then
        throw "no value for the index 'name' of element defined in : " << element.pp_xml
      end

      existing = @element_child[index]

      self.remove_element(index) if existing and (existing != element)

      @children << element
      @element_child[index] = element

      element.add_parent(self)

      changed
      return element
    end

    def new_element(index)
      accessed

      element = nil
      element = Element.new(index) unless element

      yield(element) if block_given?
      return add_element(element)
    end

    def ensure_element(index)
      accessed

      element = @element_child[index]
      return element if element

      element = Element.new(index) unless element

      yield(element) if block_given?
      return add_element(element)
    end

    def remove_element(index)
      accessed
      changed
      unless String === index or Symbol === index then
        index = index.get_the_index
      end
      element = @element_child.delete(index) if index
      @children.delete(element)
    end
  end

  module ChildElementAsChild
    require "xamplr/indexed-array"

    def child_element_child
      accessed
      @child_element_child
    end

    def child_element_child=(v)
      accessed
      @child_element_child = v
    end

    alias child_element child_element_child
    alias child_element= child_element_child=

    def init_child_element_as_child
      @child_element_child = IndexedArray.new
    end

    def add_child_element(child_element)
      accessed
      index = child_element.get_the_index
      if (nil == index) then
        throw "no value for the index 'name' of child_element defined in : " << child_element.pp_xml
      end

      existing = @child_element_child[index]

      self.remove_child_element(index) if existing and (existing != child_element)

      @children << child_element
      @child_element_child[index] = child_element

      child_element.add_parent(self)

      changed
      return child_element
    end

    def new_child_element(index)
      accessed

      child_element = nil
      child_element = ChildElement.new(index) unless child_element

      yield(child_element) if block_given?
      return add_child_element(child_element)
    end

    def ensure_child_element(index)
      accessed

      child_element = @child_element_child[index]
      return child_element if child_element

      child_element = ChildElement.new(index) unless child_element

      yield(child_element) if block_given?
      return add_child_element(child_element)
    end

    def remove_child_element(index)
      accessed
      changed
      unless String === index or Symbol === index then
        index = index.get_the_index
      end
      child_element = @child_element_child.delete(index) if index
      @children.delete(child_element)
    end
  end

  module AttributeAsChild
    require "xamplr/indexed-array"

    def attribute_child
      accessed
      @attribute_child
    end

    def attribute_child=(v)
      accessed
      @attribute_child = v
    end

    alias attribute attribute_child
    alias attribute= attribute_child=

    def init_attribute_as_child
      @attribute_child = IndexedArray.new
    end

    def add_attribute(attribute)
      accessed
      index = attribute.get_the_index
      if (nil == index) then
        throw "no value for the index 'name' of attribute defined in : " << attribute.pp_xml
      end

      existing = @attribute_child[index]

      self.remove_attribute(index) if existing and (existing != attribute)

      @children << attribute
      @attribute_child[index] = attribute

      attribute.add_parent(self)

      changed
      return attribute
    end

    def new_attribute(index)
      accessed

      attribute = nil
      attribute = Attribute.new(index) unless attribute

      yield(attribute) if block_given?
      return add_attribute(attribute)
    end

    def ensure_attribute(index)
      accessed

      attribute = @attribute_child[index]
      return attribute if attribute

      attribute = Attribute.new(index) unless attribute

      yield(attribute) if block_given?
      return add_attribute(attribute)
    end

    def remove_attribute(index)
      accessed
      changed
      unless String === index or Symbol === index then
        index = index.get_the_index
      end
      attribute = @attribute_child.delete(index) if index
      @children.delete(attribute)
    end
  end

  module OptionsAsChild
    def options_child
      accessed
      @options_child
    end

    def options_child=(v)
      accessed
      @options_child = v
    end

    alias options options_child
    alias options= options_child=

    def init_options_as_child
      @options_child = []
    end

    def add_options(options)
      accessed
      @children << options
      @options_child << options
      options.add_parent(self)
      changed
      return options
    end

    def new_options
      accessed
      options = Options.new
      yield(options) if block_given?
      return add_options(options)
    end

    alias ensure_options new_options

    def remove_options(options)
      accessed
      @options_child.delete(options)
      @children.delete(options)
    end
  end

  module IndexAttributeAsChild
    require "xamplr/indexed-array"

    def index_attribute_child
      accessed
      @index_attribute_child
    end

    def index_attribute_child=(v)
      accessed
      @index_attribute_child = v
    end

    alias index_attribute index_attribute_child
    alias index_attribute= index_attribute_child=

    def init_index_attribute_as_child
      @index_attribute_child = IndexedArray.new
    end

    def add_index_attribute(index_attribute)
      accessed
      index = index_attribute.get_the_index
      if (nil == index) then
        throw "no value for the index 'name' of index_attribute defined in : " << index_attribute.pp_xml
      end

      existing = @index_attribute_child[index]

      self.remove_index_attribute(index) if existing and (existing != index_attribute)

      @children << index_attribute
      @index_attribute_child[index] = index_attribute

      index_attribute.add_parent(self)

      changed
      return index_attribute
    end

    def new_index_attribute(index)
      accessed

      index_attribute = nil
      index_attribute = IndexAttribute.new(index) unless index_attribute

      yield(index_attribute) if block_given?
      return add_index_attribute(index_attribute)
    end

    def ensure_index_attribute(index)
      accessed

      index_attribute = @index_attribute_child[index]
      return index_attribute if index_attribute

      index_attribute = IndexAttribute.new(index) unless index_attribute

      yield(index_attribute) if block_given?
      return add_index_attribute(index_attribute)
    end

    def remove_index_attribute(index)
      accessed
      changed
      unless String === index or Symbol === index then
        index = index.get_the_index
      end
      index_attribute = @index_attribute_child.delete(index) if index
      @children.delete(index_attribute)
    end
  end

  module ResolveAsChild
    def resolve_child
      accessed
      @resolve_child
    end

    def resolve_child=(v)
      accessed
      @resolve_child = v
    end

    alias resolve resolve_child
    alias resolve= resolve_child=

    def init_resolve_as_child
      @resolve_child = []
    end

    def add_resolve(resolve)
      accessed
      @children << resolve
      @resolve_child << resolve
      resolve.add_parent(self)
      changed
      return resolve
    end

    def new_resolve
      accessed
      resolve = Resolve.new
      yield(resolve) if block_given?
      return add_resolve(resolve)
    end

    alias ensure_resolve new_resolve

    def remove_resolve(resolve)
      accessed
      @resolve_child.delete(resolve)
      @children.delete(resolve)
    end
  end

  class Elements
    include Xampl::XamplPersistedObject
    include Xampl::XamplWithDataContent

    def Elements.persisted?
      false
    end

    def persisted?
      false
    end

    @@tag = "elements"
    @@ns = "http://xampl.com/generator"
    @@ns_tag = "{http://xampl.com/generator}elements"
    @@module_name = "XamplGenerator"
    @@attributes = [
            [ :@pid, "pid" ],
    ]
    include ElementAsChild

    def Elements.lookup(pid)
      Xampl.lookup(Elements, pid)
    end

    def Elements.[](pid)
      Xampl.lookup(Elements, pid)
    end

    def pid
      @pid
    end

    def pid=(v)
      accessed
      # This is kind of optimistic, I think you are in trouble if you do this
      Xampl.auto_uncache(self) if @pid
      @pid = v
      changed
      Xampl.auto_cache(self) if v
    end

    def initialize(index=nil)
      @pid = index if index
      super()

      @pid = nil if not defined? @pid

      init_xampl_object
      init_data_content
      init_element_as_child

      yield(self) if block_given?
      changed
    end

    def clear_non_persistent_index_attributes
    end

    def append_to(other)
      other.add_elements(self)
    end

    def Elements.tag
      @@tag
    end

    def Elements.ns
      @@ns
    end

    def Elements.ns_tag
      @@ns_tag
    end

    def Elements.module_name
      @@module_name
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

    def indexed_by
      :pid
    end

    def get_the_index
      @pid
    end

    def set_the_index(index)
      @pid = index
    end

    def substitute_in_visit(visitor)
      return visitor.substitute_in_visit_elements(self) || self
    end

    def before_visit(visitor)
      visitor.before_visit_elements(self)
    end

    def visit(visitor)
      visitor.visit_elements(self)
    end

    def after_visit(visitor)
      visitor.after_visit_elements(self)
    end

    Xampl::FromXML::register(Elements::tag, Elements::ns_tag, Elements)
  end

  class Element
    include Xampl::XamplObject
    include Xampl::XamplWithDataContent

    def Element.persisted?
      false
    end

    def persisted?
      false
    end

    @@tag = "element"
    @@ns = "http://xampl.com/generator"
    @@ns_tag = "{http://xampl.com/generator}element"
    @@module_name = "XamplGenerator"
    @@attributes = [
            [ :@has_content, "hasContent" ],
                    [ :@class_name, "className" ],
                    [ :@attribute_name, "attributeName" ],
                    [ :@nstag, "nstag" ],
                    [ :@empty, "empty" ],
                    [ :@indexed_by_attr, "indexedByAttr" ],
                    [ :@persisted, "persisted" ],
                    [ :@name, "name" ],
                    [ :@kind, "kind" ],
                    [ :@namespace, "namespace" ],
                    [ :@package, "package" ],
    ]
    include ChildElementAsChild
    include AttributeAsChild

    def has_content
      accessed
      @has_content
    end

    def has_content=(v)
      accessed
      changed
      @has_content = v
    end

    def class_name
      accessed
      @class_name
    end

    def class_name=(v)
      accessed
      changed
      @class_name = v
    end

    def attribute_name
      accessed
      @attribute_name
    end

    def attribute_name=(v)
      accessed
      changed
      @attribute_name = v
    end

    def nstag
      accessed
      @nstag
    end

    def nstag=(v)
      accessed
      changed
      @nstag = v
    end

    def empty
      accessed
      @empty
    end

    def empty=(v)
      accessed
      changed
      @empty = v
    end

    def indexed_by_attr
      accessed
      @indexed_by_attr
    end

    def indexed_by_attr=(v)
      accessed
      changed
      @indexed_by_attr = v
    end

    def persisted
      accessed
      @persisted
    end

    def persisted=(v)
      accessed
      changed
      @persisted = v
    end

    def name
      accessed
      @name
    end

    def name=(v)
      accessed
      changed
      @name = v
    end

    def kind
      accessed
      @kind
    end

    def kind=(v)
      accessed
      changed
      @kind = v
    end

    def namespace
      accessed
      @namespace
    end

    def namespace=(v)
      accessed
      changed
      @namespace = v
    end

    def package
      accessed
      @package
    end

    def package=(v)
      accessed
      changed
      @package = v
    end

    def initialize(index=nil)
      @name = index if index
      super()

      @has_content = nil if not defined? @has_content
      @class_name = nil if not defined? @class_name
      @attribute_name = nil if not defined? @attribute_name
      @nstag = nil if not defined? @nstag
      @empty = nil if not defined? @empty
      @indexed_by_attr = nil if not defined? @indexed_by_attr
      @persisted = nil if not defined? @persisted
      @name = nil if not defined? @name
      @kind = nil if not defined? @kind
      @namespace = nil if not defined? @namespace
      @package = nil if not defined? @package

      init_xampl_object
      init_data_content
      init_child_element_as_child
      init_attribute_as_child

      yield(self) if block_given?
      changed
    end

    def clear_non_persistent_index_attributes
      @has_content = nil
      @class_name = nil
      @attribute_name = nil
      @nstag = nil
      @empty = nil
      @indexed_by_attr = nil
      @persisted = nil
      @name = nil
      @kind = nil
      @namespace = nil
      @package = nil
    end

    def append_to(other)
      other.add_element(self)
    end

    def Element.tag
      @@tag
    end

    def Element.ns
      @@ns
    end

    def Element.ns_tag
      @@ns_tag
    end

    def Element.module_name
      @@module_name
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

    def indexed_by
      :name
    end

    def get_the_index
      @name
    end

    def set_the_index(index)
      @name = index
    end

    def substitute_in_visit(visitor)
      return visitor.substitute_in_visit_element(self) || self
    end

    def before_visit(visitor)
      visitor.before_visit_element(self)
    end

    def visit(visitor)
      visitor.visit_element(self)
    end

    def after_visit(visitor)
      visitor.after_visit_element(self)
    end

    Xampl::FromXML::register(Element::tag, Element::ns_tag, Element)
  end

  class ChildElement
    include Xampl::XamplObject
    include Xampl::XamplWithoutContent

    def ChildElement.persisted?
      false
    end

    def persisted?
      false
    end

    @@tag = "childElement"
    @@ns = "http://xampl.com/generator"
    @@ns_tag = "{http://xampl.com/generator}childElement"
    @@module_name = "XamplGenerator"
    @@attributes = [
            [ :@element_name, "element_name" ],
                    [ :@name, "name" ],
                    [ :@namespace, "namespace" ],
                    [ :@index_class, "index_class" ],
                    [ :@index, "index" ],
                    [ :@package, "package" ],
    ]

    def element_name
      accessed
      @element_name
    end

    def element_name=(v)
      accessed
      changed
      @element_name = v
    end

    def name
      accessed
      @name
    end

    def name=(v)
      accessed
      changed
      @name = v
    end

    def namespace
      accessed
      @namespace
    end

    def namespace=(v)
      accessed
      changed
      @namespace = v
    end

    def index_class
      accessed
      @index_class
    end

    def index_class=(v)
      accessed
      changed
      @index_class = v
    end

    def index
      accessed
      @index
    end

    def index=(v)
      accessed
      changed
      @index = v
    end

    def package
      accessed
      @package
    end

    def package=(v)
      accessed
      changed
      @package = v
    end

    def initialize(index=nil)
      @name = index if index
      super()

      @element_name = nil if not defined? @element_name
      @name = nil if not defined? @name
      @namespace = nil if not defined? @namespace
      @index_class = nil if not defined? @index_class
      @index = nil if not defined? @index
      @package = nil if not defined? @package

      init_xampl_object

      yield(self) if block_given?
      changed
    end

    def clear_non_persistent_index_attributes
      @element_name = nil
      @name = nil
      @namespace = nil
      @index_class = nil
      @index = nil
      @package = nil
    end

    def append_to(other)
      other.add_child_element(self)
    end

    def ChildElement.tag
      @@tag
    end

    def ChildElement.ns
      @@ns
    end

    def ChildElement.ns_tag
      @@ns_tag
    end

    def ChildElement.module_name
      @@module_name
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

    def indexed_by
      :name
    end

    def get_the_index
      @name
    end

    def set_the_index(index)
      @name = index
    end

    def substitute_in_visit(visitor)
      return visitor.substitute_in_visit_child_element(self) || self
    end

    def before_visit(visitor)
      visitor.before_visit_child_element(self)
    end

    def visit(visitor)
      visitor.visit_child_element(self)
    end

    def after_visit(visitor)
      visitor.after_visit_child_element(self)
    end

    Xampl::FromXML::register(ChildElement::tag, ChildElement::ns_tag, ChildElement)
  end

  class Attribute
    include Xampl::XamplObject
    include Xampl::XamplWithoutContent

    def Attribute.persisted?
      false
    end

    def persisted?
      false
    end

    @@tag = "attribute"
    @@ns = "http://xampl.com/generator"
    @@ns_tag = "{http://xampl.com/generator}attribute"
    @@module_name = "XamplGenerator"
    @@attributes = [
            [ :@namespace, "namespace" ],
                    [ :@name, "name" ],
    ]

    def namespace
      accessed
      @namespace
    end

    def namespace=(v)
      accessed
      changed
      @namespace = v
    end

    def name
      accessed
      @name
    end

    def name=(v)
      accessed
      changed
      @name = v
    end

    def initialize(index=nil)
      @name = index if index
      super()

      @namespace = nil if not defined? @namespace
      @name = nil if not defined? @name

      init_xampl_object

      yield(self) if block_given?
      changed
    end

    def clear_non_persistent_index_attributes
      @namespace = nil
      @name = nil
    end

    def append_to(other)
      other.add_attribute(self)
    end

    def Attribute.tag
      @@tag
    end

    def Attribute.ns
      @@ns
    end

    def Attribute.ns_tag
      @@ns_tag
    end

    def Attribute.module_name
      @@module_name
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

    def indexed_by
      :name
    end

    def get_the_index
      @name
    end

    def set_the_index(index)
      @name = index
    end

    def substitute_in_visit(visitor)
      return visitor.substitute_in_visit_attribute(self) || self
    end

    def before_visit(visitor)
      visitor.before_visit_attribute(self)
    end

    def visit(visitor)
      visitor.visit_attribute(self)
    end

    def after_visit(visitor)
      visitor.after_visit_attribute(self)
    end

    Xampl::FromXML::register(Attribute::tag, Attribute::ns_tag, Attribute)
  end

  class Options
    include Xampl::XamplObject
    include Xampl::XamplWithDataContent

    def Options.persisted?
      false
    end

    def persisted?
      false
    end

    @@tag = "options"
    @@ns = "http://xampl.com/generator"
    @@ns_tag = "{http://xampl.com/generator}options"
    @@module_name = "XamplGenerator"
    @@attributes = [
            ]
    include IndexAttributeAsChild
    include ResolveAsChild

    def initialize
      super

      init_xampl_object
      init_data_content
      init_index_attribute_as_child
      init_resolve_as_child

      yield(self) if block_given?
      changed
    end

    def clear_non_persistent_index_attributes
    end

    def append_to(other)
      other.add_options(self)
    end

    def Options.tag
      @@tag
    end

    def Options.ns
      @@ns
    end

    def Options.ns_tag
      @@ns_tag
    end

    def Options.module_name
      @@module_name
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

    def substitute_in_visit(visitor)
      return visitor.substitute_in_visit_options(self) || self
    end

    def before_visit(visitor)
      visitor.before_visit_options(self)
    end

    def visit(visitor)
      visitor.visit_options(self)
    end

    def after_visit(visitor)
      visitor.after_visit_options(self)
    end

    Xampl::FromXML::register(Options::tag, Options::ns_tag, Options)
  end

  class IndexAttribute
    include Xampl::XamplObject
    include Xampl::XamplWithoutContent

    def IndexAttribute.persisted?
      false
    end

    def persisted?
      false
    end

    @@tag = "index-attribute"
    @@ns = "http://xampl.com/generator"
    @@ns_tag = "{http://xampl.com/generator}index-attribute"
    @@module_name = "XamplGenerator"
    @@attributes = [
            [ :@name, "name" ],
                    [ :@persisted, "persisted" ],
    ]

    def name
      accessed
      @name
    end

    def name=(v)
      accessed
      changed
      @name = v
    end

    def persisted
      accessed
      @persisted
    end

    def persisted=(v)
      accessed
      changed
      @persisted = v
    end

    def initialize(index=nil)
      @name = index if index
      super()

      @name = nil if not defined? @name
      @persisted = nil if not defined? @persisted

      init_xampl_object

      yield(self) if block_given?
      changed
    end

    def clear_non_persistent_index_attributes
      @name = nil
      @persisted = nil
    end

    def append_to(other)
      other.add_index_attribute(self)
    end

    def IndexAttribute.tag
      @@tag
    end

    def IndexAttribute.ns
      @@ns
    end

    def IndexAttribute.ns_tag
      @@ns_tag
    end

    def IndexAttribute.module_name
      @@module_name
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

    def indexed_by
      :name
    end

    def get_the_index
      @name
    end

    def set_the_index(index)
      @name = index
    end

    def substitute_in_visit(visitor)
      return visitor.substitute_in_visit_index_attribute(self) || self
    end

    def before_visit(visitor)
      visitor.before_visit_index_attribute(self)
    end

    def visit(visitor)
      visitor.visit_index_attribute(self)
    end

    def after_visit(visitor)
      visitor.after_visit_index_attribute(self)
    end

    Xampl::FromXML::register(IndexAttribute::tag, IndexAttribute::ns_tag, IndexAttribute)
  end

  class Resolve
    include Xampl::XamplObject
    include Xampl::XamplWithoutContent

    def Resolve.persisted?
      false
    end

    def persisted?
      false
    end

    @@tag = "resolve"
    @@ns = "http://xampl.com/generator"
    @@ns_tag = "{http://xampl.com/generator}resolve"
    @@module_name = "XamplGenerator"
    @@attributes = [
            [ :@namespace, "namespace" ],
                    [ :@pkg, "pkg" ],
                    [ :@preferred_prefix, "preferred_prefix" ],
    ]

    def namespace
      accessed
      @namespace
    end

    def namespace=(v)
      accessed
      changed
      @namespace = v
    end

    def pkg
      accessed
      @pkg
    end

    def pkg=(v)
      accessed
      changed
      @pkg = v
    end

    def preferred_prefix
      accessed
      @preferred_prefix
    end

    def preferred_prefix=(v)
      accessed
      changed
      @preferred_prefix = v
    end

    def initialize
      super

      @namespace = nil if not defined? @namespace
      @pkg = nil if not defined? @pkg
      @preferred_prefix = nil if not defined? @preferred_prefix

      init_xampl_object

      yield(self) if block_given?
      changed
    end

    def clear_non_persistent_index_attributes
      @namespace = nil
      @pkg = nil
      @preferred_prefix = nil
    end

    def append_to(other)
      other.add_resolve(self)
    end

    def Resolve.tag
      @@tag
    end

    def Resolve.ns
      @@ns
    end

    def Resolve.ns_tag
      @@ns_tag
    end

    def Resolve.module_name
      @@module_name
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

    def substitute_in_visit(visitor)
      return visitor.substitute_in_visit_resolve(self) || self
    end

    def before_visit(visitor)
      visitor.before_visit_resolve(self)
    end

    def visit(visitor)
      visitor.visit_resolve(self)
    end

    def after_visit(visitor)
      visitor.after_visit_resolve(self)
    end

    Xampl::FromXML::register(Resolve::tag, Resolve::ns_tag, Resolve)
  end

end

