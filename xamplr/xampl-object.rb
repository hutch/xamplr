#!/usr/bin/env ruby

module Xampl

  module InvalidXampl
	end

  module XamplObject
    attr_accessor :is_changed, :parents

    @@yaml_root = nil
		@@preferred_ns_prefix = { "http://xampl.com/" => "xampl",
		                          "http://xampl.com/generator" => "xampl-gen",
                              "http://www.w3.org/XML/1998/namespace" => "xml" }

    def init_xampl_object
      @parents = nil if not defined? @parents
      @is_changed = false if not defined? @is_changed
    end

    def init_hook
    end

		def XamplObject.ns_preferred_prefix(ns, prefix)
		  @@preferred_ns_prefix[ns] = prefix unless @@preferred_ns_prefix.has_key?(ns)
		end

		def XamplObject.lookup_preferred_ns_prefix(ns)
		  @@preferred_ns_prefix[ns]
		end
  
    def persist_required
      return false
    end

    def ignore_when_no_index
      return false
    end

		def invalidate
      self.note_invalidate
      self.persister.uncache(self) if self.persister
		  self.extend InvalidXampl
		end

		def invalid
		  return kind_of?(InvalidXampl)
		end

    def changes_accepted
      ResetIsChanged.new.start(self)
    end

    def changed
      unless Xampl.persister then
        raise UnmanagedChange.new(self)
      end
      unless @is_changed then
        @is_changed = true
        @parents.each{ | parent | parent.changed } if nil != @parents
      end
    end

    def accessed
      raise XamplIsInvalid.new(self) if invalid
    end
  
    def add_parent(xampl)
      @parents = [] if (not defined? @parents) or (nil == @parents)
      @parents << xampl
      if Xampl.persister and self.persist_required and (nil == self.persister) then
        Xampl.introduce_to_persister(self)
      end
    end
  
    def init_attributes(attr_name, attr_namespace, attr_value)
      return unless attr_name
  
      attr_name.each_index{ | i |
        self.attributes.each{ | attr_spec |
          if(2 == attr_spec.size) then
            if(attr_spec[1] == attr_name[i]) then
              self.instance_variable_set(attr_spec[0], attr_value[i])
            end
          else
            if((attr_spec[1] == attr_name[i]) and (attr_spec[2] == attr_namespace[i])) then
              self.instance_variable_set(attr_spec[0], attr_value[i])
            end
          end
        }
      }
    end

    def compare_xampl(other)
      accessed
      other.accessed if other
      return false unless self.class == other.class
      return false unless self.children.size == other.children.size
      self.children.zip(other.children).each{ | c1, c2 |
        return false unless c1.class == c2.class
        if c1.kind_of? String then
          return false unless c1 == c2
        else
          return false unless c1.compare_xampl(c2)
        end
      }
      if (defined? self._content) and (defined? other._content) then
        return false unless self._content == other._content
      else
        return false if (defined? self._content) or (defined? other._content)
      end
      return true
    end

    def ===(other)
      accessed
      other.accessed if other
      return false unless self.class == other.class
      return false unless self.children.size == other.children.size
      self.children.zip(other.children).each{ | c1, c2 |
        return false unless c1.class == c2.class
        if c1.kind_of? String then
          return false unless c1 == c2
        else
          return false unless c1 === c2
        end
      }
      if (defined? self._content) and (defined? other._content) then
        return false unless self._content == other._content
      else
        return false if (defined? self._content) or (defined? other._content)
      end
      return true
    end

    def to_ruby
      accessed
      return RubyPrinter.new.to_ruby(self)
    end

    module XamplRubyDefinition
	   @@proc = nil
#      def initialize
#	      @@proc = nil
#	    end

	    def XamplRubyDefinition.build(target = nil)
        xampl = nil
	      if @@proc then
	        local_proc = @@proc
	        @@proc = nil
	        xampl = local_proc.call(target)
					@@proc = nil
        else
          xampl = XamplRubyDefinition.build_it(target)
				end

        return xampl
	    end

      def build_it
        nil
      end
    end
    
    def XamplObject.from_string(string, target=nil)
      return FromXML.new.parse_string(string, true, false, target)
      
#       if '<' == string[0] then
#         puts "XO.from_string XML ------------------------------------------------------"
#         return FromXML.new.parse_string(string, true, false, target)
#       else
#         puts "XO.from_string RUBY ------------------------------------------------------"
#         return XamplObject.from_ruby(string, target)
#       end
    end

    def XamplObject.recover_from_string(string)
#       return FromXML.new.realise_string(string)
      return FromXML.new(true).parse_string(string, true, false, nil)
    end

    def XamplObject.from_ruby(ruby_string, target=nil)
      eval(ruby_string, nil, "ruby_definition", 0)
			target.load_needed = false if target
      xampl = XamplRubyDefinition.build(target)
    end
  
    def XamplObject.from_yaml(yaml_string, target=nil)
      unstitched = YAML::load(yaml_string)
      unstitched.stitch_yaml
			if target then
			  vars = unstitched.instance_variables
				vars.each { | ivar |
				  v = unstitched.instance_variable_get(ivar)
					target.instance_variable_set(ivar, v)
				}
				unstitched = target
			end
      return unstitched
    end

    def is_yaml_root(xampl)
      xampl == @@yaml_root
    end

    def as_yaml
      @@yaml_root = self unless @@yaml_root
      result = YAML::dump(self)
      @@yaml_root = nil if self == @@yaml_root
      return result
    end

    def persist(out="", rules=nil)
      #rules = XMLPrinter.new(out, true) if nil == rules
      #return to_xml(out, rules)
			return PersistXML.new("").start(self).done
    end
  
    def XamplObject.realise_from_xml_string(xml_string, target=nil, tokenise=true)
      return FromXML.new.realise_string(xml_string, tokenise, target)
    end

    def XamplObject.from_xml_string(xml_string, tokenise=true)
      return FromXML.new.parse_string(xml_string, tokenise)
    end

    def XamplObject.from_xml_file(file_name, tokenise=true)
      return FromXML.new.parse(file_name, tokenise)
    end
  end

  @@xampl_extends_symbols = false

  def Xampl.xampl_extends_symbols
    @@xampl_extends_symbols
  end

  def Xampl.xampl_extends_symbols=(v)
    @@xampl_extends_symbols = v

    if @@xampl_extends_symbols then
      Symbol.module_eval("include XamplExtensionsToRubyObjects")
    end
  end

  class XamplLiteralRubyObject
    def initialize(thing)
      @thing = thing
    end

    def to_xml(out="")
      out << @thing.to_s
    end
  end

  module XamplExtensionsToRubyObjects
    def to_xml(out="")
      out << self.to_s
    end
  end

  module XamplPersistedObject
    include XamplObject

    attr_reader :persister
    attr_accessor :load_needed

    def persist_required
      return true
    end

    def accessed
      raise XamplIsInvalid.new(self) if invalid
      # TODO -- why do I need to get rid of this line, alternatively, why
      # is this next line even there? Well, because accessed is now called
      # differently. But???
      #raise NoActivePersister unless @persister

      if @load_needed and @persister then
        raise NoActivePersister.new unless @persister

        if nil == Xampl.persister then
          #raise UnmanagedChange.new(self)
          if not @persister.syncing then
            Xampl.read_only(@persister){
              Xampl.lazy_load(self)
            }
          else
            puts "LOAD NEEDED(2): REFUSED (persister: #{@persister.name})"
            puts "                pid: #{self.get_the_index} #{self}"
            caller(0).each { | trace | puts "  #{trace}"}
          end
        elsif Xampl.persister != @persister then
          raise MixedPersisters.new(@persister, self)
        elsif Xampl.persister == @persister then
          if not @persister.syncing then
            Xampl.lazy_load(self)
          else
            puts "LOAD NEEDED(3): REFUSED (persister: #{@persister.name})"
            puts "                pid: #{self.get_the_index} #{self}"
            caller(0).each { | trace | puts "  #{trace}"}
          end
        else
          puts "LOAD NEEDED(4): REFUSED (persister: #{@persister.name})"
          puts "                pid: #{self.get_the_index} #{self}"
          caller(0).each { | trace | puts "  #{trace}"}
        end
      else
        puts "LOAD NEEDED(5): REFUSED (persister: #{@persister})" if @load_needed
        puts "                pid: #{self.get_the_index} #{self}" if @load_needed
        caller(0).each { | trace | puts "  #{trace}"} if @load_needed
      end
    end

    def changed
      #puts "CHANGED: is_changed #{@is_changed} xampl #{self}"
      unless Xampl.persister then
        raise UnmanagedChange.new(self)
      end
      if @persister then
        if Xampl.persister != @persister then
          raise UnmanagedChange.new(self)
        end
        if @persister.block_changes then
          raise BlockedChange.new(self)
        end
      end
      unless @is_changed then
        @is_changed = true
        if @persister then
          @persister.has_changed self
        end
      end
    end

    def force_load
      @load_needed = true
      @is_changed = false
      @persister.has_not_changed(self) if @persister
      self.clear_non_persistent_index_attributes
      self.methods.grep(/init_.*_as_child/).each{ | method_name |
        self.send(method_name)
      }
      @children = []
    end

    def reset_contents
      self.clear_non_persistent_index_attributes
      self.methods.grep(/init_.*_as_child/).each{ | method_name |
        self.send(method_name)
      }
      @children = []
    end

    def introduce_persister(persister)
      #accessed
      if @persister and (@persister != persister) then
        raise AlreadyKnownToPersister.new(self, persister)
      end
      @persister = persister
      return true
    end

    def init_xampl_object
      super
      @persister = nil
      @load_needed = false
      if (Xampl.persister and Xampl.persister.automatic) then
        Xampl.persister.introduce(self)
      else
        introduce_persister(nil)
      end
    end

    def describe_yourself
      nil
    end
  end

  class XMLText
    attr_accessor  :namespaces, :prefix_ns_map, :ns, :first_text, :text

    def initialize
      @namespaces = []
      @prefix_ns_map = {}
      @first_text = nil
      @text = nil
      @ns = nil
    end

    def start_element(pp, depth)
      @namespaces = {}
      @namespaces[pp.namespace] = pp.namespace

      depth += 1

      if @first_text then
        @text << "<" << pp.qname 

        pp.attributeCount.times{ | i |
          @text << " " << pp.attributeQName(i) << "='" << pp.attributeValue(i) << "'"

          prefix = pp.attributePrefix(i)
          if prefix then
            @prefix_ns_map[prefix] = pp.attributeNamespace(i)
          end
        }
      else
        @first_text = "<" << pp.qname 

        pp.attributeCount.times{ | i |
          @first_text << " " << pp.attributeQName(i) << "='" << pp.attributeValue(i) << "'"

          prefix = pp.attributePrefix(i)
          if prefix then
            @prefix_ns_map[prefix] = pp.attributeNamespace(i)
          end
        }
        @text = ""
      end

      prefix = pp.prefix
      if prefix then
        @prefix_ns_map[prefix] = pp.namespace
      end

      if @ns != pp.namespace then
        @text << " xmlns='" << pp.namespace << "'"
      end

      @text << ">"

      return depth
    end

    def end_element(pp, depth)
      depth -= 1

      @text << "</"
      @text << pp.prefix << ":" if pp.prefix
      @text << pp.name << ">"

      return depth
    end

    def to_s
      @text
    end

    def to_xml(xml_printer=nil)
      # xml_printer should be an XMLPrinter (and it knows about
      # namespace prefixes)

      @text
    end

    def build(pp)
      @namespaces = {}
      @first_text = nil
      @text = nil

      depth = start_element(pp, 0)

      while true 
        raise XamplException.new("unexpected end of document") if pp.endDocument?

        case pp.nextEvent
          when Xampl_PP::START_DOCUMENT
            raise XamplException.new("unexpected start of document")
          when Xampl_PP::END_DOCUMENT
            raise XamplException.new("unexpected end of document")
          when Xampl_PP::START_ELEMENT
            depth = start_element(pp, depth)
          when Xampl_PP::END_ELEMENT
            depth = end_element(pp, depth)
            break if depth <= 0
          when Xampl_PP::TEXT, Xampl_PP::CDATA_SECTION, Xampl_PP::ENTITY_REF
            @text << pp.text
           #when Xampl_PP::IGNORABLE_WHITESPACE
           #when Xampl_PP::PROCESSING_INSTRUCTION
           #when Xampl_PP::COMMENT
           #when Xampl_PP::DOCTYPE
        end
      end

      @namespaces = @namespaces.keys

      @prefix_ns_map.sort.each { | prefix, ns |
        @first_text << " xmlns:" << prefix << "='" << ns << "'"
      }
      @first_text << @text
      @text = @first_text
      @first_text = nil
    end
  end

  class XamplIsInvalid < Exception
    attr_reader :msg, :xampl

    def initialize(xampl)
      @xampl = xampl
      @msg = "Invalid Xampl:: #{xampl}"
    end

    def message
      @msg
    end
  end

  class AlreadyKnownToPersister < Exception
    attr_reader :msg, :xampl

    def initialize(xampl, persister)
      @xampl = xampl
      @msg = "#{xampl} #{xampl.get_the_index} is already known by a persister: #{xampl.persister.name}, so cannot use persister #{persister.name}"
    end

    def message
      @msg
    end
  end

  class XamplException < Exception
    attr_reader :name, :msg

    def initialize(name, message=nil)
      @name = name
      @msg = message ? message : ""
    end

    def message
      "XamplException #{@name} #{@msg}"
    end
  end
end

