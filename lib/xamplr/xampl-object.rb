
module Xampl

  module XamplObject
    attr_accessor :is_changed, :parents

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

      attr_name.each_index do |i|
        self.attributes.each do |attr_spec|
          if (2 == attr_spec.size) then
            if (attr_spec[1] == attr_name[i]) then
              self.instance_variable_set(attr_spec[0], attr_value[i])
            end
          else
            if ((attr_spec[1] == attr_name[i]) and (attr_spec[2] == attr_namespace[i])) then
              self.instance_variable_set(attr_spec[0], attr_value[i])
            end
          end
        end
      end
    end

    def compare_xampl(other)
      accessed
      other.accessed if other
      return false unless self.class == other.class
      return false unless self.children.size == other.children.size
      self.children.zip(other.children).each do |c1, c2|
        return false unless c1.class == c2.class
        if c1.kind_of? String then
          return false unless c1 == c2
        else
          return false unless c1.compare_xampl(c2)
        end
      end
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
      self.children.zip(other.children).each do |c1, c2|
        return false unless c1.class == c2.class
        if c1.kind_of? String then
          return false unless c1 == c2
        else
          return false unless c1 === c2
        end
      end
      if (defined? self._content) and (defined? other._content) then
        return false unless self._content == other._content
      else
        return false if (defined? self._content) or (defined? other._content)
      end
      return true
    end

    def indexed_by
      nil
    end

    def to_s
      if self.persisted? then
        "<<#{ self.class.name } #{ self.object_id } [#{ self.get_the_index }]#{ @is_changed ? ' DIRTY' : ''}>>" 
      elsif self.indexed_by then
        "<<#{ self.class.name } #{ self.object_id } [#{ self.get_the_index }]>>"
      else
        "<<#{ self.class.name } #{ self.object_id }>>"
      end
    end

    def inspect
      self.to_s
    end

    def to_ruby(mentions=nil)
      accessed
      return RubyPrinter.new(mentions).to_ruby(self)
    end

    module XamplRubyDefinition
      @@proc = nil

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

    def persist(out="", mentions=nil, rules=nil)
      persist_xml_new = PersistXML.new(out, mentions)
      return persist_xml_new.start(self).done
    end

    ################################################################################################
    ################################################################################################
    ################################################################################################

    def Xampl.find_things_to_delete(scheduled_before=Time.now.to_i)
      things = Xampl.query do | q |
        q.add_condition('scheduled-delete-at', :lte, scheduled_before)
      end
      things
    end

    def should_schedule_delete?
      #puts "Xampl#should_schedule_delete? is NOT IMPLEMENTED FOR: #{ self.class.name }"
      false
    end

    def schedule_a_deletion_if_needed(at=Time.now.to_i)
      @scheduled_for_deletion_at = should_schedule_delete? ? at.to_s : nil #TODO -- necessary??
    end

    ################################################################################################
    ################################################################################################
    ################################################################################################



    def XamplObject.realise_from_xml_string(xml_string, target=nil, tokenise=true)
      xampl = FromXML.new.realise_string(xml_string, tokenise, target)
      return xampl
    end

    def XamplObject.from_xml_string(xml_string, tokenise=true)
      return FromXML.new.parse_string(xml_string, tokenise)
    end

    def XamplObject.from_xml_file(file_name, tokenise=true)
      return FromXML.new.parse(file_name, tokenise)
    end
  end

    def Xampl.from_xml_string(xml_string, tokenise=true)
      return FromXML.new.parse_string(xml_string, tokenise)
    end

    def Xampl.from_xml_file(file_name, tokenise=true)
      return FromXML.new.parse(file_name, tokenise)
    end

end

