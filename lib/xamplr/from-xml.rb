require 'libxml'

module Xampl

  class FromXML

    attr :checkWellFormed, false
    attr :is_realising, false
    attr :tokenise_content, false

    @reader = nil

    @@by_tag = {}
    @@by_ns_tag = {}

    def initialize(recovering=false)
      @recovering = recovering

      @attribute_name = Array.new(32)
      @attribute_namespace = Array.new(32)
      @attribute_value = Array.new(32)

      @insert_end_element = false
      @faking_an_end_element = false
      @just_opened_an_element = false
    end

    def FromXML.reset_registry
      @@by_tag = {}
      @@by_ns_tag = {}
    end

    def FromXML.register(tag, ns_tag, klass)
      @@by_ns_tag[ns_tag] = [ klass ]
      a = @@by_tag[tag]
      if (nil == a) then
        @@by_tag[tag] = [ klass ]
      else
        found = false
        a.each { | thing | found = found | (thing == klass) }
        a << klass unless found
      end
    end

    def FromXML.registered(name)
      klass = @@by_ns_tag[name]
      klass = @@by_tag[name] unless klass
      klass = [] unless klass
      return klass
    end

    def resolve(name)
      #TODO -- ???
      return name
    end

    def setup_parse(filename, tokenise_content=true, is_realising=false)
      @resolver = self

      @is_realising = is_realising
      @tokenise_content = tokenise_content

      @reader = LibXML::XML::Reader.file(filename,
                                         :options => LibXML::XML::Parser::Options::NOENT |
                                                 LibXML::XML::Parser::Options::NONET |
                                                 LibXML::XML::Parser::Options::NOCDATA |
                                                 LibXML::XML::Parser::Options::DTDATTR |
                                                 LibXML::XML::Parser::Options::COMPACT)
      #TODO CLOSE THIS THING!!
    end

    def setup_parse_string(string, tokenise_content=true, is_realising=false)
      @resolver = self

      @is_realising = is_realising
      @tokenise_content = tokenise_content

      #      setInput(string)
      @reader = LibXML::XML::Reader.string(string,
                                           :options => LibXML::XML::Parser::Options::NOENT |
                                                   LibXML::XML::Parser::Options::NONET |
                                                   LibXML::XML::Parser::Options::NOCDATA |
                                                   LibXML::XML::Parser::Options::DTDATTR |
                                                   LibXML::XML::Parser::Options::COMPACT)
      #TODO CLOSE THIS THING!!
    end

    def parse(filename, tokenise_content=true, is_realising=false)
      begin
        setup_parse(filename, tokenise_content, is_realising)
        element, ignore = parse_element
        return element
      rescue Exception => e
        puts "trouble parsing file: '#{filename}'"
        puts "Exception: #{e}"
        raise
      end
    end

    def realise_string(string, tokenise_content=true, target=nil)
      return parse_string(string, tokenise_content, true, target)
    end

    def parse_string(string, tokenise_content=true, is_realising=false, target=nil)
      begin
        setup_parse_string(string, tokenise_content, is_realising)
        element, ignore = parse_element(nil, target)
        return element
      rescue Exception => e
        puts "trouble parsing string: '#{string}'"
        puts "Exception: #{e}"
        raise
      end
    end

    def FromXML.tokenise_string(str, strip=true)
      return nil unless str
      str.strip! if strip
      str.gsub!(/[ \n\r\t][ \n\r\t]*/, " ")
      return str
    end

    def parse_element(parent=nil, target=nil)
      find_the_first_element
      return unless start_element?

      namespace = @reader.namespace_uri
      name = @reader.local_name

      existing_element = nil
      element = nil

      requires_caching = false

      build_attribute_arrays

      if ((nil != namespace) and (0 < namespace.size)) then
        klass_name = "{#{namespace}}#{name}"
        klasses = FromXML.registered(klass_name)
        if (0 == klasses.size) then
          xml_text = XMLText.new
          xml_text.build(self)
          xml_text = parent.note_adding_text_content(xml_text, @is_realising)
          parent.add_content(xml_text, @tokenise_content) if xml_text
          return xml_text, false
        end
        if (1 < klasses.size) then
          raise XamplException.new("there is more than one '#{name}' tag in namespace '#{namespace}'\nplease report this error")
        end
      else
        klasses = FromXML.registered(name)
        if (0 == klasses.size) then
          raise XamplException.new("do not recognise tag '#{name}' (no namespace specified)")
        end
        if (1 < klasses.size) then
          raise XamplException.new("there is more than one '#{name}' tag (no namespace specified)")
        end
      end

      unless @is_realising then
        @attribute_value.size.times do |i|
          FromXML.tokenise_string @attribute_value[i]
        end
      end

      if target then
        element = target
        target.load_needed = false
        target = nil
        element.init_attributes(@attribute_name, @attribute_namespace, @attribute_value)
        element.note_attributes_initialised(@is_realising)
      else
        if klasses[0].persisted? then
          @attribute_name.each_index do |i|
            if @attribute_name[i] == klasses[0].persisted?.to_s then
              existing_element = Xampl.find_known(klasses[0], @attribute_value[i])
              if existing_element then
                # so we've found the element. Now what??? We can do several
                # reasonable things:
                #
                #    1) continue parsing into the found element
                #    2) simply return the found element
                #    3) replace the found element with the new element
                #
                # The first one is dubious, so we won't.
                # The second and third option both make complete sense
                #
                # We are going to do the second
                #
                # BTW, 'existing element' means a representation of this element already in memory
                # puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                # puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                # puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                # puts "FOUND AN EXISTING THING... #{ klasses[0] } #{ @attribute_value[i] }"
                # puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                # puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                # puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                # caller(0).each { | trace | puts "  #{trace}"}
                #                   existing_element.reset_contents
                #                   element = existing_element
                #                   existing_element = nil
                #                  puts "#{File.basename(__FILE__)} #{__LINE__} EXISTING ELEMENT: #{ existing_element }"
                #                  puts "#{File.basename(__FILE__)} #{__LINE__} WOW, must handle the existing element correctly"
                element = existing_element #TODO -- IS THIS RIGHT????????????????????????
              end
              unless element then
                element = klasses[0].new
                requires_caching = @recovering
#                  puts "#{File.basename(__FILE__)} #{__LINE__} WOW, what about recovering????"
                #TODO -- IS THIS RIGHT????????????????????????
                requires_caching = true #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                unless @recovering then
                  element.force_load if parent
                end
                element.note_created(@is_realising)
              end

              break
            end
          end
        end

        unless element then
          element = klasses[0].new
          element.note_created(@is_realising)
        end

        element.note_initialise_attributes_with(@attribute_name, @attribute_namespace, @attribute_value, @is_realising)
        element.init_attributes(@attribute_name, @attribute_namespace, @attribute_value)
        element.note_attributes_initialised(@is_realising)

        if requires_caching and element and element.persist_required then
          Xampl.cache(element)
        end

        #element = element.note_add_to_parent(parent, @is_realising)
        #element.append_to(parent) if parent
      end

      while next_reader_event
        case current_node_type

=begin
TODO -- can these ever happen?
          when START_DOCUMENT
            return element if @recovering
            return existing_element || element
          when END_DOCUMENT
            return element if @recovering
            return existing_element || element

=end

          when LibXML::XML::Reader::TYPE_ELEMENT
            child, ignore_child = parse_element(element)

            unless ignore_child then
              case child
                when XamplObject then
                  child = child.note_add_to_parent(element, @is_realising) if child
                  child = element.note_add_child(child, @is_realising) if element
                  child.append_to(element) if element and child
                when XMLText then
                  puts "UNRECOGNISED Well-formed XML: #{child.to_s[0..25]}..."
                else
                  puts "WHAT IS THIS??? #{child.class.name}"
              end
            end
          when LibXML::XML::Reader::TYPE_END_ELEMENT
            element = element.note_closed(@is_realising)
            return element if @recovering
            return existing_element || element
          when LibXML::XML::Reader::TYPE_TEXT, LibXML::XML::Reader::TYPE_CDATA, LibXML::XML::Reader::TYPE_SIGNIFICANT_WHITESPACE, LibXML::XML::Reader::TYPE_ENTITY_REFERENCE
            if element.has_mixed_content then
              text = @reader.read_string
              the_text = element.note_adding_text_content(text, @is_realising)
              element << the_text
            else
              text = @reader.read_string
              the_text = element.note_adding_text_content(text, @is_realising)
              element.add_content(the_text, false)
            end
          else
        end
      end

      return element if @recovering
      return existing_element || element
    end

    def current_node_type
      if @faking_an_end_element then
        LibXML::XML::Reader::TYPE_END_ELEMENT
      else
        @reader.node_type
      end
    end

=begin
    def describe_current_element_type()
      case @reader.node_type
        when LibXML::XML::Reader::TYPE_ATTRIBUTE
          puts "ATTRIBUTE"
        when LibXML::XML::Reader::TYPE_DOCUMENT
          puts "DOCUMENT"
        when LibXML::XML::Reader::TYPE_ELEMENT
          attribute_count = @reader.attribute_count
          puts "ELEMENT #{ @reader.local_name }, ns: #{ @reader.namespace_uri }, #attributes: #{ attribute_count }, depth: #{ @reader.depth }"
          puts "        FAKING END ELEMENT" if @faking_an_end_element
        when LibXML::XML::Reader::TYPE_END_ELEMENT
          puts "END ELEMENT"
        when LibXML::XML::Reader::TYPE_TEXT
          puts "TEXT [[#{ @reader.read_string }]]"
        when LibXML::XML::Reader::TYPE_CDATA
          puts "CDATA [[#{ @reader.read_string }]]"
        when LibXML::XML::Reader::TYPE_SIGNIFICANT_WHITESPACE
          puts "SIGNIFICANT white space [[#{ @reader.read_string }]]"
        when LibXML::XML::Reader::TYPE_ENTITY_REFERENCE
          puts "entity ref"
        when LibXML::XML::Reader::TYPE_WHITESPACE
          puts "whitespace"
        when LibXML::XML::Reader::TYPE_PROCESSING_INSTRUCTION
          puts "processing instruction"
        when LibXML::XML::Reader::TYPE_COMMENT
          puts "comment"
        when LibXML::XML::Reader::TYPE_DOCUMENT_TYPE
          puts "doc type"

        when LibXML::XML::Reader::TYPE_XML_DECLARATION
          puts "xml decl"
        when LibXML::XML::Reader::TYPE_NONE
          puts "NONE!!"
        when LibXML::XML::Reader::TYPE_NOTATION
          puts "notifiation"
        when LibXML::XML::Reader::TYPE_DOCUMENT_FRAGMENT
          puts "doc fragment"
        when LibXML::XML::Reader::TYPE_ENTITY
          puts "entity"
        when LibXML::XML::Reader::TYPE_END_ENTITY
          puts "end entity"
        else
          puts "UNKNOWN: #{@reader.node_type}"
      end
    end
=end

    def next_reader_event
      if @insert_end_element then
        @faking_an_end_element = true
        @insert_end_element = false
        return
      end

      @faking_an_end_element = false

      #describe_current_element_type

      okay = @reader.read

      @just_opened_an_element = start_element?
      @insert_end_element = (@just_opened_an_element and @reader.empty_element?)

      #describe_current_element_type

      okay
    end

    def start_element?
      current_node_type == LibXML::XML::Reader::TYPE_ELEMENT
    end

    def whitespace?
      current_note_type == LibXML::XML::Reader::TYPE_WHITESPACE
    end

    def find_the_first_element
      while true do
        break if start_element?
        break unless next_reader_event
      end
      @just_opened_an_element = start_element?
    end

    def build_attribute_arrays

      @attribute_name.clear
      @attribute_namespace.clear
      @attribute_value.clear

      return unless LibXML::XML::Reader::TYPE_ELEMENT == current_node_type

      if @reader.has_attributes? then
        attribute_count = @reader.attribute_count
        @reader.move_to_first_attribute
        attribute_count.times do | i |
          if @reader.namespace_declaration? then
            @reader.move_to_next_attribute
            next
          end

          @attribute_name << @reader.local_name
          @attribute_namespace << @reader.namespace_uri
          @attribute_value << @reader.value

          @reader.move_to_next_attribute
        end
      end
    end

    def attributeCount
      return @attribute_name.length
    end

    def attributeName(i)
      return @attribute_name[i]
    end

    def attributeNamespace(i)
      return @attribute_namespace[i]
    end

    def attributeValue(i)
      return @attribute_value[i]
    end

    def depth
      return @reader.depth
    end

    def line
      return @reader.line_number
    end

    def column
      return @reader.column_number
    end
  end

end
