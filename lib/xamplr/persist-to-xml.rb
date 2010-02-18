require 'libxml'

module Xampl

  class PersistXML < Visitor
    attr_accessor :ns_to_prefix, :start_body, :body, :out, :mentions

    def initialize(out="", mentions=nil, substitutions={})
      super()

      @out = out
      @was_attr = false

      @mentions = mentions
      @pid_substitutions = substitutions

      @ns_to_prefix = {}
      @start_body = nil
      @body = ""
      @attr_list = nil
    end

    def cycle(xampl)
      raise XamplException.new(:cycle_detected_in_xampl_cluster) unless xampl.kind_of?(XamplPersistedObject)
      return true
    end

    def revisit(xampl)
      return true
    end

    def register_ns(ns)
      if (0 == ns.length) then
        return ""
      end

      prefix = ns_to_prefix[ns]
      if (nil == prefix) then
        preferred = XamplObject.lookup_preferred_ns_prefix(ns)
        prefix = "" << preferred << ":" if preferred
        prefix = "ns" << ns_to_prefix.size.to_s << ":" unless prefix
        ns_to_prefix[ns] = prefix
      end
      return prefix
    end

    def attr_esc_fast(s)
      #NOTE -- there are known issues with using Ruby 1.9.1 and libxml-ruby, which this is using. Seems to mostly
      #        be related to DOM and XPATH but...
      unless defined?(@@doc) then
        @@doc = LibXML::XML::Document.new()
        @@doc.root = LibXML::XML::Node.new('r')
        @@attr = LibXML::XML::Attr.new(@@doc.root, 'v', 'v')
      end

      @@attr.value = s.to_s
      (@@doc.root.to_s)[6..-4]
    end

    def attr_esc_slow(s)
      if (s.kind_of? XamplObject)
        return attr_esc(s.to_xml)
      end

#      stupid_test()

      result = s.to_s.dup

      result.gsub!("&", "&amp;")
      result.gsub!("<", "&lt;")
      result.gsub!(">", "&gt;")
      result.gsub!("'", "&apos;")
      result.gsub!("\"", "&quot;")

      return result
    end

    alias attr_esc attr_esc_fast

#    def content_esc(s)
#      #NO! the attribute has the right to compact white space
#      unless defined?(@@doc) then
#        @@doc = LibXML::XML::Document.new()
#        @@doc.root = LibXML::XML::Node.new('r')
#        @@attr = LibXML::XML::Attr.new(@@doc.root, 'v', 'v')
#      end
#
#      @@attr.value = s
#      (@@doc.root.to_s)[6..-4]
#    end

    #TODO -- use libxml for this too
    def content_esc(s)
      result = s.to_s.dup

      return result if (s.kind_of? XamplObject)

      result.gsub!("&", "&amp;")
      result.gsub!("<", "&lt;")
      result.gsub!(">", "&gt;")

      return result
    end

    def attribute(xampl)
      @attr_list = []
      pattr = xampl.indexed_by.to_s

      if (nil != xampl.attributes) then
        xampl.attributes.each do |attr_spec|
          prefix = (2 < attr_spec.length) ? register_ns(attr_spec[2]) : ""
          value = nil
          if pattr == attr_spec[1] then
            value = @pid_substitutions[xampl]
#            puts "#{ File.basename __FILE__ }:#{ __LINE__ } [#{__method__}] xampl: #{ xampl }, substitute: #{ value }" if value
            value = xampl.instance_variable_get(attr_spec[0]) unless value
          else
            value = xampl.instance_variable_get(attr_spec[0])
          end
          @attr_list << (" " << prefix << attr_spec[1] << '="' << attr_esc(value) << '"') unless nil == value
        end
      end
    end

    def persist_attribute(xampl)
      @attr_list = []
      pattr = xampl.indexed_by.to_s
      if (nil != xampl.attributes) then
        xampl.attributes.each do |attr_spec|
          if pattr == attr_spec[1] then
            prefix = (2 < attr_spec.length) ? register_ns(attr_spec[2]) : ""
            value = @pid_substitutions[xampl]
#            puts "#{ File.basename __FILE__ }:#{ __LINE__ } [#{__method__}] xampl: #{ xampl }, substitute: #{ value }" if value
            value = xampl.instance_variable_get(attr_spec[0]) unless value
            @attr_list << (" " << prefix << attr_spec[1] << '="' << attr_esc(value) << '"') unless nil == value
            break
          end
        end
      end
    end

    def show_attributes
      result = @attr_list.join(" ")
      if (0 == result.length) then
        return ""
      else
        return result
      end
    end

    def start_element(xampl)
      tag = xampl.tag
      ns = xampl.ns
      tag_info = "" << "<" << register_ns(ns) << tag
      unless @start_body then
        attribute(xampl)
        attr_defn = show_attributes
        @start_body = "" << tag_info << attr_defn
        @was_attr = true if 0 < attr_defn.size
      else
        if xampl.persist_required then
          @mentions << xampl if @mentions
          @no_children = true
          persist_attribute(xampl)
        else
          attribute(xampl)
        end
        @body << tag_info << show_attributes
      end
    end

    def end_element(xampl)
      tag = xampl.tag
      ns = xampl.ns
      @body << "</" << register_ns(ns) << tag << ">"
    end

    def define_ns
      result = ""
      ns_to_prefix.each do |ns, prefix|
#        result = sprintf("%s xmlns:%s='%s'", result, prefix[0..-2], ns)
        result = sprintf("%s xmlns:%s=\"%s\"", result, prefix[0..-2], ns)
      end
      return result
    end

    def done
      out << @start_body << define_ns << @body
    end

    def before_visit_without_content(xampl)
      start_element(xampl)
      @body << "/>"
    end

    def before_visit_simple_content(xampl)
      start_element(xampl)
      if @no_children then
        @body << "/>"
      else
        @body << ">"
        begin
          @body.concat(content_esc(xampl._content)) if xampl._content
        rescue => e
          begin
            s = xampl._content.force_encoding(@body.encoding)
            @body.concat(content_esc(s)) if xampl._content
          rescue => e
            puts "EXCEPTION: #{ e }"
            puts "body encoding: #{ @body.encoding }"
            puts "xampl._content encoding: #{ xampl._content.encoding }"
            puts "content_esc(xampl._content) encoding: #{ content_esc(xampl._content).encoding }"
            puts "xampl._content: [[[#{ xampl._content }]]]"
#          puts "body so far: [[[#{ @body }]]]"
            raise e
          end
        end
        end_element(xampl)
      end
    end

    def before_visit_data_content(xampl)
      start_element(xampl)
      if @no_children then
        @body << "/>"
      else
        @body << ">"
        @body << content_esc(xampl._content) if xampl._content
      end
    end

    def after_visit_data_content(xampl)
      end_element(xampl) unless @no_children
    end

    def before_visit_mixed_content(xampl)
      if @no_children then
        @body << "/>"
      else
        start_element(xampl)
        @body << ">"
      end
    end

    def after_visit_mixed_content(xampl)
      end_element(xampl) unless @no_children
    end

    def before_visit(xampl)
      if xampl.respond_to? "before_visit_by_element_kind" then
        xampl.before_visit_by_element_kind(self)
      else
        @body << xampl.to_s
      end
    end

    def after_visit(xampl)
      xampl.after_visit_by_element_kind(self) if xampl.respond_to? "after_visit_by_element_kind"
    end

    def visit_string(string)
      @body << string
    end
  end

  module XamplObject
    def to_xml(out="", skip=[])
      PersistXML.new(out).start(self).done
    end

    def substituting_to_xml(opts={})
      substitutions = opts[:substitutions] || {}
      PersistXML.new("", [], substitutions).start(self).done
    end
  end

end

