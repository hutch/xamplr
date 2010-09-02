#encoding: utf-8
module Xampl

  class CountingVisitor < Visitor
    attr_accessor :count

    def initialize
      super
      @count = 0
    end

    def before_visit(xampl)
      @count += 1
    end
  end

  class ResetIsChanged < Visitor
    def initialize
      super
    end

    def start(xampl, verbose=false)
      @verbose = verbose
      if verbose
        puts "RESET IS CHANGED.... #{xampl}"
        puts "SKIPPING!!!" unless xampl.persist_required and xampl.load_needed
      end

      return if xampl.persist_required and xampl.load_needed
      super(xampl)
    end

    def before_visit(xampl)
      if xampl.is_changed then
        puts "RESET CHANGED: #{xampl} and continue" if verbose
        xampl.is_changed = false;
      else
        puts "RESET CHANGED: #{xampl} block" if verbose
        @no_children = true
      end
    end
  end

  class MarkChangedDeep < Visitor
    def initialize
      super
    end

    def before_visit(xampl)
      xampl.changed if xampl.persist_required
    end
  end

  class PrettyXML < Visitor
    attr_accessor :ns_to_prefix, :start_body, :body, :out
    attr_accessor :indent, :indent_step

    @@compact = true

    def PrettyXML.compact
      @@compact
    end

    def PrettyXML.compact=(v)
      @@compact = v
    end

    def initialize(out="", skip=[])
      super()

      @out               = out
      @indent            = ""
      @indent_step       = "  "
      @start_attr_indent = ""
      @was_attr          = false

      @depth             = 0

      @skip              = {}
      skip.each { |ns|
        @skip[ns] = ns
      }

      @ns_to_prefix      = {}
      @start_body        = nil
      @body              = ""
      @attr_list         = nil

      @insert_comment    = nil
    end

    def short_circuit
      body << @insert_comment if @insert_comment
      @insert_comment = nil
    end

    def cycle(xampl)
      @short_circuit  = true
      @insert_comment = "<!-- CYCLE -->"
      return true
    end

    def revisit(xampl)
      @insert_comment = "<!-- You've seen this before -->"
      #body << "<!-- You've seen this before -->"
      return true
    end

    def register_ns(ns)
      if (0 == ns.length) then
        return ""
      end

      prefix = ns_to_prefix[ns]
      if (nil == prefix) then
        preferred        = XamplObject.lookup_preferred_ns_prefix(ns)
        prefix = "" << preferred << ":" if preferred
        prefix = "ns" << ns_to_prefix.size.to_s << ":" unless prefix
        ns_to_prefix[ns] = prefix
      end
      return prefix
    end

    def attr_esc(s)
      if (s.kind_of? XamplObject)
        return attr_esc(s.to_xml)
      end

      result = s.to_s.dup

      result.gsub!("&", "&amp;")
      result.gsub!("<", "&lt;")
      result.gsub!(">", "&gt;")
      result.gsub!("'", "&apos;")
      result.gsub!("\"", "&quot;")

      return result
    end

    def content_esc(s)
      result = s.to_s.dup

      return result if (s.kind_of? XamplObject)

      result.gsub!("&", "&amp;")
      result.gsub!("<", "&lt;")

      return result
    end

    def attribute(xampl)
      @attr_list = []
      pid        = nil
      if (nil != xampl.attributes) then
        xampl.attributes.each do |attr_spec|
          unless @skip[attr_spec[2]] then
            value = xampl.instance_variable_get(attr_spec[0])
            if value then
              prefix = (2 < attr_spec.length) ? register_ns(attr_spec[2]) : ""
              @attr_list << (" " << prefix << attr_spec[1] << "='" << attr_esc(value) << "'")
            end
          end
        end
        @attr_list.sort!
      end
#@attr_list << " xampl:marker='OKAY: #{ xampl }'"
    end

    def persist_attribute(xampl)
      @attr_list = []
      if xampl.persist_required then
        index = xampl.indexed_by.to_s
        if index then
          value = xampl.get_the_index
          @attr_list << (" " << index << "='" << attr_esc(value) << "'") if value
        end
      else
        attribute(xampl)
#@attr_list << " xampl:wtf='WTF??'"
      end
    end

    def show_attributes(attr_indent)
      if (nil == @attr_list) then
        return ""
      else
        result = @attr_list.join(attr_indent)
        if (0 == result.length) then
          return ""
        else
          return result
        end
      end
    end

    def do_indent
      return "\n" << @indent << (@indent_step * @depth)
    end

    def start_element(xampl)
      xampl.accessed

      if @revisiting or @cycling then
        @short_circuit = true
        persist_attribute(xampl)
      else
        attribute(xampl)
      end

      tag         = xampl.tag
      ns          = xampl.ns
      indent      = do_indent
      tag_info    = "" << "<" << register_ns(ns) << tag
      attr_indent = "" << indent << (" " * tag_info.size)
      unless @start_body then
        @start_attr_indent = attr_indent
        attr_defn          = show_attributes(attr_indent)
        @start_body        = "" << indent << tag_info << attr_defn
        @was_attr = true if 0 < attr_defn.size
      else
        @body << indent << tag_info << show_attributes(attr_indent)
      end
    end

    def end_element(xampl)
      tag = xampl.tag
      ns  = xampl.ns
      if @@compact then
        @body << "</" << register_ns(ns) << tag << ">"
      else
        @body << do_indent << "</" << register_ns(ns) << tag << ">"
      end
    end

    def define_ns
      result = ""
      indent = @was_attr
      ns_to_prefix.each do |ns, prefix|
        result = sprintf("%s%s xmlns:%s='%s'", result, indent ? @start_attr_indent : "", prefix[0..-2], ns)
        indent = true
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
      @body << ">"
      @body << content_esc(xampl._content) if xampl._content
      end_element(xampl)
    end

    def before_visit_data_content(xampl)
      start_element(xampl)
      @body << ">"
      @body << content_esc(xampl._content) if xampl._content
      @depth += 1
    end

    def after_visit_data_content(xampl)
      @depth += -1
      end_element(xampl)
    end

    def before_visit_mixed_content(xampl)
      start_element(xampl)
      @body << ">"
      @depth += 1
    end

    def after_visit_mixed_content(xampl)
      @depth -= 1
      end_element(xampl)
    end

    def before_visit(xampl)
      unless xampl.kind_of?(XamplObject) and @skip[xampl.ns] then
        if xampl.respond_to? "before_visit_by_element_kind" then
          xampl.before_visit_by_element_kind(self)
        else
          @body << xampl.to_s
        end
      else
        @no_children = true
      end
    end

    def after_visit(xampl)
      xampl.after_visit_by_element_kind(self) if xampl.respond_to? "after_visit_by_element_kind"
    end

    def visit_string(string)
      @body << string
    end
  end

  class CopyXML < Visitor
    attr_accessor :ns_to_prefix, :start_body, :body

    def CopyXML.copy(root, translate_pids={})
      CopyXML.new.make_copy(root, translate_pids)
    end

    def make_copy(root, translate_pids)
      @was_attr                    = false

      @ns_to_prefix                = {}
      @start_body                  = nil
      @body                        = ""
      @attr_list                   = nil

      @pid_translations_old_to_new = translate_pids
      @pid_translations_new_to_old = translate_pids.invert

#      @persisted_xampl_found = { @current_root.get_the_index => root }
      @persisted_xampl_found       = {(@current_root || root).get_the_index => root} #TODO -- is root ever okay here?
      @copies_by_old_pid           = {}

      while true do
        copy_these             = []

        @persisted_xampl_found.each do |pid, xampl|
          copy_these << xampl unless @copies_by_old_pid[pid]
        end

        break if 0 == copy_these.length

        @persisted_xampl_found = {}
        copy_these.each do |xampl|
          @current_root                                   = xampl
          @out                                            = ""
          @copies_by_old_pid[@current_root.get_the_index] = @out

          copy_xampl(@current_root)
        end
      end

      return @copies_by_old_pid
    end

    def copy_xampl(root)
      start(root).done
    end

    @@base_pid = Time.now.to_i.to_s + "_"
    @@gen_pid  = 0

    def get_the_new_pid(xampl)
      current_pid                         = xampl.get_the_index
      @persisted_xampl_found[current_pid] = xampl

      new_pid                             = @pid_translations_old_to_new[current_pid]

      unless new_pid then
        @@gen_pid                                 += 1
        new_pid                                   = @@base_pid + @@gen_pid.to_s

        @pid_translations_old_to_new[current_pid] = new_pid
        @pid_translations_new_to_old[new_pid]     = current_pid
      end

      return new_pid
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
        preferred        = XamplObject.lookup_preferred_ns_prefix(ns)
        prefix = "" << preferred << ":" if preferred
        prefix = "ns" << ns_to_prefix.size.to_s << ":" unless prefix
        ns_to_prefix[ns] = prefix
      end
      return prefix
    end

    def attr_esc(s)
      if (s.kind_of? XamplObject)
        return attr_esc(s.to_xml)
      end

      result = s.to_s.dup

      result.gsub!("&", "&amp;")
      result.gsub!("<", "&lt;")
      result.gsub!(">", "&gt;")
      result.gsub!("'", "&apos;")
      result.gsub!("\"", "&quot;")

      return result
    end

    def content_esc(s)
      result = s.to_s.dup

      return result if (s.kind_of? XamplObject)

      result.gsub!("&", "&amp;")
      result.gsub!("<", "&lt;")

      return result
    end

    def attribute(xampl)
      @attr_list = []
      if (nil != xampl.attributes) then
        xampl.attributes.each { |attr_spec|
          prefix = (2 < attr_spec.length) ? register_ns(attr_spec[2]) : ""
          value  = get_the_new_pid(xampl.instance_variable_get(attr_spec[0]))
          @attr_list << (" " << prefix << attr_spec[1] << "='" << attr_esc(value) << "'") \
                unless nil == value
        }
      end
    end

    def persist_attribute(xampl)
      @attr_list = []
      pattr      = xampl.indexed_by.to_s
      if (nil != xampl.attributes) then
        xampl.attributes.each { |attr_spec|
          if pattr == attr_spec[1] then
            prefix = (2 < attr_spec.length) ? register_ns(attr_spec[2]) : ""
            value  = xampl.instance_variable_get(attr_spec[0])
            @attr_list << (" " << prefix << attr_spec[1] << "='" << attr_esc(value) << "'") \
                  unless nil == value
            break
          end
        }
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
      tag      = xampl.tag
      ns       = xampl.ns
      tag_info = "" << "<" << register_ns(ns) << tag
      unless @start_body then
        attribute(xampl)
        attr_defn   = show_attributes
        @start_body = "" << tag_info << attr_defn
        @was_attr = true if 0 < attr_defn.size
      else
        if xampl.persist_required then
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
      ns  = xampl.ns
      @body << "</" << register_ns(ns) << tag << ">"
    end

    def define_ns
      result = ""
      ns_to_prefix.each { |ns, prefix|
        result = sprintf("%s xmlns:%s='%s'", result, prefix[0..-2], ns)
      }
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
        @body << content_esc(xampl._content) if xampl._content
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
    def pp_xml(out="", skip=[])
      PrettyXML.new(out, skip).start(self).done
    end

    def copy_xampl(root, translate_pids={})
      CopyXML.copy(root, translate_pids)
    end

    def mark_changed_deep
      MarkChangedDeep.new.start(self)
    end
  end

end

