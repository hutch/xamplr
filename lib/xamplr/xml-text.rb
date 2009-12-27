module Xampl

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

        pp.attributeCount.times do |i|
          @text << " " << pp.attributeQName(i) << "='" << pp.attributeValue(i) << "'"

          prefix = pp.attribute_prefix(i)
          if prefix then
            @prefix_ns_map[prefix] = pp.attribute_namespace(i)
          end
        end
      else
        @first_text = "<" << pp.qname

        pp.attributeCount.times do |i|
          @first_text << " " << pp.attributeQName(i) << "='" << pp.attributeValue(i) << "'"

          prefix = pp.attribute_prefix(i)
          if prefix then
            @prefix_ns_map[prefix] = pp.attribute_namespace(i)
          end
        end
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

      @prefix_ns_map.sort.each do |prefix, ns|
        @first_text << " xmlns:" << prefix << "='" << ns << "'"
      end
      @first_text << @text
      @text = @first_text
      @first_text = nil
    end
  end

end
