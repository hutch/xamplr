#!/usr/bin/env ruby

module Xampl

  def Xampl.make(klass, pid=nil)
    xampl = klass.new
    xampl.set_the_index(pid) if nil != pid
    yield(xampl) if block_given?
    return xampl
  end

  module XamplWithoutContent
    def has_mixed_content
      false
    end

    def children
      return []
    end

    def before_visit_by_element_kind(visitor)
      visitor.before_visit_without_content(self)
    end

    def visit_by_element_kind(visitor)
      visitor.visit_without_content(self)
    end

    def after_visit_by_element_kind(visitor)
      visitor.after_visit_without_content(self)
    end

    def test_to_xml(out="", rules=nil)
      accessed
      rules = XMLPrinter.new(out) if nil == rules

      rules.attribute(self)
      rules.start_root_element(tag, ns, true)

      return rules.done
    end

    def test_to_xml_internal(rules)
      if rules.persisting && self.persist_required then
        rules.persist_attribute(self)
        rules.persisted_element(tag, ns)
        return
      end

      rules.attribute(self)
      rules.start_element(tag, ns, true)
    end

    def <<(other)
      if (other.respond_to?("append_to"))
        other.append_to(self)
      else
        raise XamplException.new("no content allowed")
      end
      return self
    end
  end

  module XamplWithSimpleContent
    def initialize
      super
      @_content = nil unless defined? @_content
    end

    def has_mixed_content
      false
    end

    def before_visit_by_element_kind(visitor)
      visitor.before_visit_simple_content(self)
    end

    def visit_by_element_kind(visitor)
      visitor.visit_simple_content(self)
    end

    def after_visit_by_element_kind(visitor)
      visitor.after_visit_simple_content(self)
    end

    def _content
      accessed
      @_content
    end

    def _content=(v)
      accessed
      v = v.to_s if (v.kind_of? Symbol) and !Xampl.xampl_extends_symbols
      v.extend(XamplExtensionsToRubyObjects) unless v.kind_of? Symbol
      @_content = v
      changed
    end

    alias content _content
    alias content= _content=

    def add_content(new_content, tokenise=false)
      return if nil == new_content
      accessed

      if (nil == @_content) then
        @_content = new_content.to_s
        @_content.extend(XamplExtensionsToRubyObjects)
      else
        @_content << new_content.to_s
      end

      FromXML.tokenise_string(@_content, false) if tokenise
      @_content = nil if 0 == @_content.size

      changed
    end

    def children
      return []
    end

    def test_to_xml(out="", rules=nil)
      accessed
      rules = XMLPrinter.new(out) if nil == rules

      rules.attribute(self)
      if (nil == self._content)
        rules.start_root_element(tag, ns, true)
        rules.end_root_element(tag, ns, true)
      else
        rules.start_root_element(tag, ns, false)
        rules._content(content)
        rules.end_root_element(tag, ns, false)
      end

      return rules.done
    end

    def test_to_xml_internal(rules)
      if rules.persisting && self.persist_required then
        rules.persist_attribute(self)
        rules.persisted_element(tag, ns)
        return
      end

      rules.attribute(self)
      if (nil == self._content)
        rules.start_element(tag, ns, true)
        rules._content(content)
        rules.end_element(tag, ns, true)
      else
        rules.start_element(tag, ns, false)
        rules._content(content)
        rules.end_element(tag, ns, false)
      end
    end

    def <<(other)
      if (other.respond_to?("append_to"))
        raise XamplException.new("simple content only")
      else
        add_content(other)
      end
      return self
    end
  end

  module XamplWithDataContent

    def initialize
      super
      init_data_content
    end

    def has_mixed_content
      false
    end

    def before_visit_by_element_kind(visitor)
      visitor.before_visit_data_content(self)
    end

    def visit_by_element_kind(visitor)
      visitor.visit_data_content(self)
    end

    def after_visit_by_element_kind(visitor)
      visitor.after_visit_data_content(self)
    end

    def init_data_content
      @_content = nil if not defined? @_content
      @children = [] if not defined? @children
    end

    def children
      accessed
      return @children
    end

    def _content
      accessed
      @_content
    end

    def _content=(v)
      accessed
      v = v.to_s if (v.kind_of? Symbol) and !Xampl.xampl_extends_symbols
      v.extend(XamplExtensionsToRubyObjects) unless v.kind_of? Symbol
      @_content = v
      changed
    end

    alias content _content
    alias content= _content=

    def add_content(new_content, tokenise=false)
      return if nil == new_content
      accessed

      if (nil == @_content) then
        @_content = new_content.to_s
        @_content.extend(XamplExtensionsToRubyObjects)
      else
        @_content << new_content.to_s
      end

      FromXML.tokenise_string(@_content, false) if tokenise
      @_content = nil if 0 == @_content.size

      changed
    end

    def test_to_xml(out="", rules=nil)
      accessed
      rules = XMLPrinter.new(out) if nil == rules

      rules.attribute(self)
      if (0 == children.length) && (nil == content)
        rules.start_root_element(tag, ns, true)
        rules.end_root_element(tag, ns, true)
      else
        rules.start_root_element(tag, ns, false)
        rules._content(content)
        children.each{ | child |
          child.test_to_xml_internal(rules)
        }
        rules.end_root_element(tag, ns, false)
      end

      return rules.done
    end

    def test_to_xml_internal(rules)
      if rules.persisting && self.persist_required then
        rules.persist_attribute(self)
        rules.persisted_element(tag, ns)
        return
      end

      rules.attribute(self)
      if (self.persist_required && self.load_needed) || ((0 == children.length) && (nil == content))
        rules.start_element(tag, ns, true)
        rules.end_element(tag, ns, true)
      else
        rules.start_element(tag, ns, false)
        rules._content(content)
        children.each{ | child |
          child.test_to_xml_internal(rules)
        }
        rules.end_element(tag, ns, false)
      end
    end

    def <<(other)
      if (other.respond_to?("append_to"))
        other.append_to(self)
      else
        add_content(other)
      end
      return self
    end
  end

  module XamplWithMixedContent
    def initialize
      super
      init_mixed_content
    end

    def init_mixed_content
      @children = [] if not defined? @children
    end

    def has_mixed_content
      true
    end

    def before_visit_by_element_kind(visitor)
      visitor.before_visit_mixed_content(self)
    end

    def visit_by_element_kind(visitor)
      visitor.visit_mixed_content(self)
    end

    def after_visit_by_element_kind(visitor)
      visitor.after_visit_mixed_content(self)
    end

    def children
      accessed
      return @children
    end

    def add_content(new_content, tokenise=false)
      return if nil == new_content
      accessed

      new_content = new_content.to_s

      last_child = @children.last
      if last_child and (last_child.kind_of? String) then
        last_child << new_content
        FromXML.tokenise_string(last_child, false) if tokenise
      else
        FromXML.tokenise_string(new_content, false) if tokenise
        new_content.extend(XamplExtensionsToRubyObjects)
        @children << new_content unless 0 == new_content.size
      end

      changed
    end

    def test_to_xml(out="", rules=nil)
      accessed
      rules = XMLPrinter.new(out) if nil == rules

      rules.attribute(self)
      if (0 == children.length)
        rules.start_root_element(tag, ns, true)
        rules.end_root_element(tag, ns, true)
      else
        rules.start_root_element(tag, ns, false)
        rules.now_as_mixed
        children.each{ | child |
          if (child.respond_to? "test_to_xml_internal")
            child.test_to_xml_internal(rules)
          else
            rules._content(child)
          end
        }
        rules.now_as_before
        rules.end_root_element(tag, ns, false)
      end

      return rules.done
    end

    def test_to_xml_internal(rules)
      if rules.persisting && self.persist_required then
        rules.persist_attribute(self)
        rules.persisted_element(tag, ns)
        return
      end

      rules.attribute(self)
      if (self.persist_required && self.load_needed) || (0 == children.length)
        rules.start_element(tag, ns, true)
        rules.end_element(tag, ns, true)
      else
        rules.start_element(tag, ns, false)
        rules.now_as_mixed
        children.each{ | child |
          if (child.respond_to? "test_to_xml_internal")
            child.test_to_xml_internal(rules)
          else
            rules._content(child)
          end
        }
        rules.now_as_before
        rules.end_element(tag, ns, false)
      end
    end

    def <<(other)
      if (other.respond_to?("append_to"))
        other.append_to(self)
      else
        add_content(other)
      end
      return self
    end
  end
end

