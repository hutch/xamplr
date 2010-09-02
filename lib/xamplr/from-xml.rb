# encoding utf-8

require 'nokogiri'

module Xampl

  class FromXML

    attr :checkWellFormed #1.9.1 , false
    attr :is_realising #1.9.1 , false
    attr :tokenise_content #1.9.1 , false

    @reader     = nil

    @@by_tag    = {}
    @@by_ns_tag = {}

    def initialize(recovering=false)
      @recovering             = recovering

      @attribute_name         = Array.new(32)
      @attribute_namespace    = Array.new(32)
      @attribute_value        = Array.new(32)

      @insert_end_element     = false
      @faking_an_end_element  = false
      @just_opened_an_element = false
    end

    def FromXML.reset_registry
      @@by_tag    = {}
      @@by_ns_tag = {}
    end

    def FromXML.register(tag, ns_tag, klass)
      @@by_ns_tag[ns_tag] = [klass]
      a                   = @@by_tag[tag]
      if (nil == a) then
        @@by_tag[tag] = [klass]
      else
        found = false
        a.each { |thing| found = found | (thing == klass) }
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
      #TODO -- ??? don't seem to need it, this is for specific named entities
      return name
    end

    def setup_parse(filename, tokenise_content=true, is_realising=false)
      xml = File.read(filename)
      setup_parse_string(xml, tokenise_content, is_realising)
    end

    def setup_parse_string(string, tokenise_content=true, is_realising=false)
      @resolver         = self

      @is_realising     = is_realising
      @tokenise_content = tokenise_content

=begin
      STRICT	=	0	 	 Strict parsing
      RECOVER	=	1 << 0	 	 Recover from errors
      NOENT	=	1 << 1	 	 Substitute entities
      DTDLOAD	=	1 << 2	 	 Load external subsets
      DTDATTR	=	1 << 3	 	 Default DTD attributes
      DTDVALID	=	1 << 4	 	 validate with the DTD
      NOERROR	=	1 << 5	 	 suppress error reports
      NOWARNING	=	1 << 6	 	 suppress warning reports
      PEDANTIC	=	1 << 7	 	 pedantic error reporting
      NOBLANKS	=	1 << 8	 	 remove blank nodes
      SAX1	=	1 << 9	 	 use the SAX1 interface internally
      XINCLUDE	=	1 << 10	 	 Implement XInclude substitition
      NONET	=	1 << 11	 	 Forbid network access
      NODICT	=	1 << 12	 	 Do not reuse the context dictionnary
      NSCLEAN	=	1 << 13	 	 remove redundant namespaces declarations
      NOCDATA	=	1 << 14	 	 merge CDATA as text nodes
      NOXINCNODE	=	1 << 15	 	 do not generate XINCLUDE START/END nodes
      DEFAULT_XML	=	RECOVER	 	 the default options used for parsing XML documents
      DEFAULT_HTML	=	RECOVER | NOERROR | NOWARNING | NONET	 	 the default options used for parsing HTML documents
=end

      options           = Nokogiri::XML::ParseOptions::RECOVER | Nokogiri::XML::ParseOptions::NOENT | Nokogiri::XML::ParseOptions::NONET | Nokogiri::XML::ParseOptions::NOCDATA | Nokogiri::XML::ParseOptions::DTDATTR

      utf8_string       = string.force_encoding('utf-8')
      url               = nil
      encoding          = nil

      @reader           = Nokogiri::XML::Reader.from_memory(utf8_string, url, encoding, options)
    end

    def parse(filename, tokenise_content=true, is_realising=false)
      begin
        setup_parse(filename, tokenise_content, is_realising)
        element, ignore = parse_element
        return element
      rescue => e
        raise RuntimeError, "trouble parsing file: '#{filename}' -- #{ e }", e.backtrace
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
      rescue => e
        raise RuntimeError, "trouble parsing string: '#{string}' -- #{ e }", e.backtrace
      end
    end

    def chew
      xml   = @reader.outer_xml
      depth = @reader.depth
      @reader.read
      while depth != @reader.depth do
        @reader.read
      end
      return xml
    end


    def parse_element(parent=nil, target=nil)
#      puts caller(0)[0..5]

      find_the_first_element
      return unless start_element?

      namespace        = @reader.namespace_uri
      name             = @reader.local_name
      existing_element = nil
      element          = nil

      requires_caching = false

      build_attribute_arrays

      if ((nil != namespace) and (0 < namespace.size)) then
        klass_name = "{#{namespace}}#{name}"
        klasses    = FromXML.registered(klass_name)
        if (0 == klasses.size) then
          # The class has not been registered (either it was never generated, or it was never loaded)
          begin
            #discard this node and all children, but say something
            thing = chew
            puts "#{ ::File.basename __FILE__ }:#{ __LINE__ } [#{__method__}] UNRECOGNISED CHILD ELEMENTS: class: #{ klass_name }\n#{ thing }"
            return nil, true
          rescue => e
            puts "Ohhhh NO! #{ e }"
            puts e.backtrace
            raise e
          end
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
        element            = target
        target.load_needed = false
        target             = nil
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
                element          = klasses[0].new
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

        Xampl.cache(element) if requires_caching && element && element.persist_required
      end

      while next_reader_event do
        if @reader.value? then
          text = @reader.value
          text = text.force_encoding('utf-8') unless 'UTF-8' == text.encoding
          the_text = element.note_adding_text_content(text, @is_realising)
          if element.has_mixed_content then
            element << the_text
          else
            element.add_content(the_text, false)
          end
        elsif Nokogiri::XML::Node::ELEMENT_NODE == @reader.node_type then
          child, ignore_child = parse_element(element)

          unless ignore_child then
            case child
              when XamplObject then
                child = child.note_add_to_parent(element, @is_realising) if child
                child = element.note_add_child(child, @is_realising) if element
                child.append_to(element) if element && child
              when XMLText then
                #TODO -- get rid of this puts
                puts "UNRECOGNISED Well-formed XML: #{child.to_s[0..25]}..."
              else
                #TODO -- get rid of this puts
                puts "WHAT IS THIS??? #{child.class.name}"
            end
          end
        elsif Nokogiri::XML::Node::ELEMENT_DECL == @reader.node_type then
          element = element.note_closed(@is_realising)
          return element if @recovering
          return existing_element || element
        else
          puts "WTF??(#{ @reader.depth }) name: #{ @reader.name }, #{ say_node_type(@reader.node_type)}/#{ @reader.node_type }\n#{ @reader.outer_xml }"
        end
      end

      return element if @recovering
      return existing_element || element
    end

    def FromXML.tokenise_string(str, strip=true)
      return nil unless str
      str.strip! if strip
      str.gsub!(/[ \n\r\t][ \n\r\t]*/, " ")
      return str
    end

    def current_node_type
      if @faking_an_end_element then
        Nokogiri::XML::Node::ELEMENT_DECL
      else
        @reader.node_type
      end
    end

    def next_reader_event
      if @insert_end_element then
        @faking_an_end_element = true
        @insert_end_element    = false
        return
      end

      @faking_an_end_element  = false

      begin
        okay = @reader.read
      rescue => e
        raise RuntimeError, "WHAT?? -- #{ e }", e.backtrace
      end

      @just_opened_an_element = self.start_element?
      @insert_end_element     = (@just_opened_an_element and @reader.empty_element?)
      okay
    end

    def start_element?
      current_node_type == Nokogiri::XML::Node::ELEMENT_NODE
    end

    def whitespace?
      #there is no whitespace type with nokogiri
      #TODO -- this is not actually called, so...
      @reader.value? && @reader.value.match(/\S/).nil?
    end

    def find_the_first_element
      while true do
        break if start_element?
        break unless next_reader_event
      end
      @just_opened_an_element = start_element?
      @insert_end_element     = (@just_opened_an_element and @reader.empty_element?)
    end

    def build_attribute_arrays
      @attribute_name.clear
      @attribute_namespace.clear
      @attribute_value.clear

      return unless @reader.attributes?

      @reader.attributes.each do |name, value|
        @attribute_name << name
        @attribute_namespace << nil
        @attribute_value << value
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
