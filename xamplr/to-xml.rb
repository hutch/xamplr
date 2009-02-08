
module Xampl

  class XMLPrinter
    attr_accessor :ns_to_prefix, :start_body, :body, :out, :mixed, :persisting
  
    def initialize(out, persisting=false)
      @out = out
      @persisting = persisting

      @ns_to_prefix = {}
      @start_body = ""
      @body = ""
      @attr_list = nil
      @mixed = 0
    end
  
    def now_as_mixed
      @mixed = @mixed + 1
    end
  
    def now_as_before
      @mixed = @mixed - 1 if(0 < @mixed)
    end
  
    def register_ns(ns)
      if(0 == ns.length) then
        return ""
      end
  
      prefix = ns_to_prefix[ns]
      if(nil == prefix) then
		    preferred = XamplObject.lookup_preferred_ns_prefix(ns)
        prefix = "" << preferred << ":" if preferred
        prefix = "ns" << ns_to_prefix.size.to_s << ":" unless prefix
        ns_to_prefix[ns] = prefix
      end
      return prefix
    end
  
    def attr_esc(s)
      if(s.kind_of? XamplObject)
        return attr_esc(s.to_xml)
      end

      result = s.to_s.dup
      #result = s.to_xml

      result.gsub!("&", "&amp;")
      result.gsub!("<", "&lt;")
      result.gsub!(">", "&gt;")
      result.gsub!("'", "&apos;")
      result.gsub!("\"", "&quot;")

      return result
    end
  
    def content_esc(s)
      result = s.to_s.dup
      #result = s.to_xml

      return result if(s.kind_of? XamplObject)

      result.gsub!("&", "&amp;")
      result.gsub!("<", "&lt;")

      return result
    end
  
    def attribute(xampl)
      @attr_list = []
      if (nil != xampl.attributes) then
        xampl.attributes.each{ | attr_spec |
          prefix = (2 < attr_spec.length) ? register_ns(attr_spec[2]) : ""
          value = xampl.instance_variable_get(attr_spec[0])
          @attr_list << " " << prefix << attr_spec[1] << "='" << attr_esc(value) << "'" \
                unless nil == value
        }
      end
    end
  
    def persist_attribute(xampl)
      @attr_list = []
      index = xampl.indexed_by[1..-1]
      if (nil != index) then
          value = xampl.get_the_index
          @attr_list << " " << index << "='" << attr_esc(value) << "'" if value 
      end
    end
  
    def show_attributes
      if(nil == @attr_list) then
        return ""
      else
        result = @attr_list.join
        if(0 == result.length) then
          return ""
        else
          return result
        end
      end
    end
  
    def start_root_element(tag, ns, empty=false)
      if(empty) then
        @start_body << "<" << register_ns(ns) << tag << show_attributes
        @body = "/>"
      else
        @start_body << "<" << register_ns(ns) << tag << show_attributes
        @body = ">"
      end
    end
  
    def start_element(tag, ns, empty=false)
      if(empty) then
        @body << "<" << register_ns(ns) << tag << show_attributes << "/>"
      else
        @body << "<" << register_ns(ns) << tag << show_attributes << ">"
      end
    end

    def persisted_element(tag, ns)
      @body << "<" << register_ns(ns) << tag << show_attributes << "/>"
    end
  
    def _content(text)
      if nil != text then
        if text.kind_of? XMLText then
          @body << text.to_xml(self)
        else
          @body << content_esc(text)
        end
      end
    end
    alias content _content
  
    def end_root_element(tag, ns, empty)
      @body << "</" << register_ns(ns) << tag << ">" if(!empty)
    end
  
    def end_element(tag, ns, empty)
      @body << "</" << register_ns(ns) << tag << ">" if(!empty)
    end
  
    def define_ns
      result = ""
      ns_to_prefix.each{ | ns, prefix |
        result = sprintf("%s xmlns:%s='%s'", result, prefix[0..-2], ns)
      }
      return result
    end
  
    def done
      out << start_body << define_ns << body
    end
  end
end  
