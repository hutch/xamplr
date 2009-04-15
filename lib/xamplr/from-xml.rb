require "xamplr-pp"

module Xampl

  class FromXML < Xampl_PP

    attr :checkWellFormed, false
    attr :is_realising, false
    attr :tokenise_content, false

    @@by_tag = {}
    @@by_ns_tag = {}

    def initialize(recovering=false)
      super()
      @recovering = recovering
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
      return name
    end

    def setup_parse(filename, tokenise_content=true, is_realising=false)
      @processNamespace = true
      @reportNamespaceAttributes = false
      @checkWellFormed = false
      @resolver = self

      @is_realising = is_realising
      @tokenise_content = tokenise_content

      setInput(File.new(filename))
    end

    def setup_parse_string(string, tokenise_content=true, is_realising=false)
      @processNamespace = true
      @reportNamespaceAttributes = false
      @checkWellFormed = false
      @resolver = self

      @is_realising = is_realising
      @tokenise_content = tokenise_content

      setInput(string)
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
      next_interesting_event unless parent

      existing_element = nil
      element = nil

      requires_caching = false

      if startElement? then
        if ((nil != @namespace) and (0 < @namespace.size)) then
          klass_name = "{#{@namespace}}#{@name}"
          klasses = FromXML.registered(klass_name)
          if (0 == klasses.size) then
            xml_text = XMLText.new
            xml_text.build(self)
            xml_text = parent.note_adding_text_content(xml_text, @is_realising)
            parent.add_content(xml_text, @tokenise_content) if xml_text
# puts "#{__LINE__ }:: add_content [#{xml_text}] --> [#{parent.content}]"
            return xml_text, false
          end
          if (1 < klasses.size) then
            raise XamplException.new("there is more than one '#{@name}' tag in namespace '#{@namespace}'\nplease report this error")
          end
        else
          klasses = FromXML.registered(@name)
          if (0 == klasses.size) then
            raise XamplException.new("do not recognise tag '#{@name}' (no namespace specified)")
          end
          if (1 < klasses.size) then
            raise XamplException.new("there is more than one '#{@name}' tag (no namespace specified)")
          end
        end

        unless @is_realising then
          @attributeValue.size.times{ | i |
            FromXML.tokenise_string @attributeValue[i]
          }
        end

        if target then
          element = target
          target.load_needed = false
          target = nil
          element.init_attributes(@attributeName, @attributeNamespace, @attributeValue)
          element.note_attributes_initialised(@is_realising)
        else
          if klasses[0].persisted? then
            @attributeName.each_index{ | i |
              if @attributeName[i] == klasses[0].persisted?.to_s then
                existing_element = Xampl.find_known(klasses[0], @attributeValue[i])
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
                  # puts "FOUND AN EXISTING THING... #{ klasses[0] } #{ @attributeValue[i] }"
                  # puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                  # puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                  # puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                  # caller(0).each { | trace | puts "  #{trace}"}
                  #                   existing_element.reset_contents
                  #                   element = existing_element
                  #                   existing_element = nil
                end
                unless element then
                  element = klasses[0].new
                  requires_caching = @recovering
                  unless @recovering then
                    element.force_load if parent
                  end
                  element.note_created(@is_realising)
                end

                break
              end
            }
          end

          unless element then
            element = klasses[0].new
            element.note_created(@is_realising)
          end

          element.note_initialise_attributes_with(@attributeName, @attributeNamespace, @attributeValue, @is_realising)
          element.init_attributes(@attributeName, @attributeNamespace, @attributeValue)
          element.note_attributes_initialised(@is_realising)

          if requires_caching and element and element.persist_required then
            # puts "ELEMENT: #{element}, #{element.class.name}"
            Xampl.cache(element)
            # found = Xampl.find_known(element.class, element.get_the_index)
            # puts "OK? #{found == element} found: #{found}, element: #{element}"
            # puts "=============================================================================="
          end

          #element = element.note_add_to_parent(parent, @is_realising)
          #element.append_to(parent) if parent
        end

        while not endDocument?
          case nextEvent
          when START_DOCUMENT
            return element if @recovering
            return existing_element || element
          when END_DOCUMENT
            return element if @recovering
            return existing_element || element
          when START_ELEMENT
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
#                 if child.kind_of? XamplObject then
              #                   child = child.note_add_to_parent(element, @is_realising) if child
              #                   child = element.note_add_child(child, @is_realising) if element
              #                   child.append_to(element) if element and child
              #                 else
              #                   puts "WHAT IS THIS??? #{child.class.name}"
              #                 end
            end
          when END_ELEMENT
            element = element.note_closed(@is_realising)
            return element if @recovering
            return existing_element || element
          when TEXT, CDATA_SECTION, ENTITY_REF
            if element.has_mixed_content then
              the_text = element.note_adding_text_content(@text, @is_realising)
              # element.add_content(the_text, @tokenise_content)
              element << the_text
# puts "#{__LINE__ }:: add_content [#{the_text}]"
            else
              unless whitespace? then
                the_text = element.note_adding_text_content(@text, @is_realising)
                # 16 Mar 2007 -- this was making preformatted text content impossible
                # element.add_content(the_text, @tokenise_content)
                element.add_content(the_text, false)
# puts "#{__LINE__ }:: add_content [#{the_text}] --> [#{element.content}]"
              end
            end
          end
        end
      end
      return element if @recovering
      return existing_element || element
    end

    def next_interesting_event
      if (endDocument?) then
        return Xampl_PP::END_DOCUMENT
      end

      boring = true
      while boring do
        event = nextEvent
        case event
        when Xampl_PP::START_DOCUMENT
          boring = true
        when Xampl_PP::END_DOCUMENT
          boring = false
        when Xampl_PP::START_ELEMENT
          boring = false
        when Xampl_PP::END_ELEMENT
          boring = false
        when Xampl_PP::TEXT
          boring = false
        when Xampl_PP::CDATA_SECTION
          boring = false
        when Xampl_PP::ENTITY_REF
          boring = false
        when Xampl_PP::IGNORABLE_WHITESPACE
          boring = true
        when Xampl_PP::PROCESSING_INSTRUCTION
          boring = true
        when Xampl_PP::COMMENT
          boring = true
        when Xampl_PP::DOCTYPE
          boring = true
        end
      end
      return event
    end

    def attributeCount
      return @attributeName.length
    end

    def attributeName(i)
      return @attributeName[i]
    end

    def attributeNamespace(i)
      return @attributeNamespace[i]
    end

    def attributeQName(i)
      return @attributeQName[i]
    end

    def attributePrefix(i)
      return @attributePrefix[i]
    end

    def attributeValue(i)
      return @attributeValue[i]
    end

    def depth
      return depth
    end

    def line
      return line
    end

    def column
      return column
    end
  end
end
