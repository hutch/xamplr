require 'fileutils'
require 'getoptlong'
require 'set'

module XamplGenerator
  require "xamplr"
  require "xamplr/xampl-hand-generated"
  require "xamplr/simpleTemplate/simple-template"
  require "xamplr/graphml-out.rb"
  require "xamplr/yuml-out.rb"

  class Attribute
    attr_accessor :tag_name
  end

  class StandardGeneratorTemplates
    include TemplateEngine

    attr_accessor :element, :package_name, :place, :lookup_element, :options, :required_packages

    def initialize
      super
      @element = nil
      @package_name = nil
      @place = nil
      @lookup_element = {}
      @options = nil
      @required_packages = {}
    end
  end

  class Generator

    attr_accessor :elements_map, :options, :templates

    @@standard_templates = [
            "xamplr/templates/child_modules.template",
            "xamplr/templates/child.template",
            "xamplr/templates/child_indexed.template",
            "xamplr/templates/element_classes.template",
            "xamplr/templates/element_data.template",
            "xamplr/templates/element_empty.template",
            "xamplr/templates/element_mixed.template",
            "xamplr/templates/element_simple.template",
            "xamplr/templates/package.template",
    ]

    def initialize(options_in = nil, *predefined_elements)
      @elements_map = {}
      @xpp = nil
      @templates = nil
      @generated_package_map = nil

      if options_in then
        @options = options_in
      else
        @options = Xampl.make(Options) do |options|
          options.new_index_attribute("id")
          options.new_index_attribute("pid").persisted = true;

          options.new_resolve do |resolver|
            resolver.pkg = "XamplAdHoc"
            resolver.namespace=""
          end
        end
      end

      predefined_elements.each do |elements|
        throw :elements_need_a_pid unless elements.pid
        @elements_map[elements.pid] = elements
      end
    end

    def start_element(parent)
      name = @xpp.name
      namespace = @xpp.namespace
      namespace = "" unless namespace
      is_empty = @xpp.emptyElement

      nstag = "{{#{namespace}}}#{name}"

      elements = @elements_map[namespace]
      if nil == elements then
        elements = Elements.new
        @elements_map[namespace] = elements
      end

      element = elements.element_child[name]
      if nil == element then
        element = elements.new_element(name)
      end

      element.namespace = namespace
      element.nstag = nstag
      element.empty = is_empty

      @xpp.attribute_name.each_index do |i|
        attribute = Attribute.new
        attribute.name = @xpp.attribute_name[i]
        attribute.namespace = @xpp.attribute_namespace[i]
        element.add_attribute(attribute)
      end

      if parent then
        parent.new_child_element(nstag) do |ce|
          ce.element_name = name
          ce.namespace = namespace
        end
      end
      return element
    end

    def parse_filename(filename)
      @xpp = Xampl_PP.new
      @xpp.input = File.new(filename)
      parse
    end

    def parse_string(string)
      @xpp = Xampl_PP.new
      @xpp.input = string
      parse
    end

    def parse
      element_stack = []
      current_element = nil

      while not @xpp.endDocument? do
        case @xpp.nextEvent
          when Xampl_PP::START_ELEMENT
            element_stack.push current_element unless nil == current_element
            current_element = start_element(current_element)
          when Xampl_PP::END_ELEMENT
            current_element = element_stack.pop
          when Xampl_PP::TEXT,
                  Xampl_PP::CDATA_SECTION,
                  Xampl_PP::ENTITY_REF
            if current_element then
              text = @xpp.text
              if (nil != @xpp.text) then
                text = text.strip
                current_element.found_text_content if 0 < text.size
              end
            end
        end
      end
    end

    def comprehend_from_files(filenames)
      filenames.each do |filename|
        puts "comprehend file #{filename}"
        parse_filename(filename)
      end
    end

    def comprehend_from_strings(strings)
      strings.each do |string|
        parse_string(string)
      end
    end

    def analyse
      namespace_package_map = {}
      namespace_prefix_map = {}
      options.resolve_child.each do |resolve|
        namespace_package_map[resolve.namespace] = resolve.pkg
      end

      @elements_map.each do |ns, elements|
        package = namespace_package_map[ns]

        elements.element_child.each do |element|
          element.package = package
          element.analyse(options)
        end
      end

      @required_packages = {}
      @elements_map.each do |ns, elements|
        package = namespace_package_map[ns]

        required = @required_packages[package]
        unless required then
          required = {}
          @required_packages[package] = required
        end

        elements.element_child.each do |element|
          element.child_element_child.each do |child_element|
            celement = child_element.find_element(@elements_map)
            #required[celement.package] = celement.package
            unless package == celement.package then
              required[celement.package] = celement.package
            end
          end
        end
      end
    end

    def ensure_templates
      return if @templates

      @templates = StandardGeneratorTemplates.new
      @templates.compile_scripts(@@standard_templates)
    end

    def find_place(directory_name, package)
      #puts "find_place:: package: #{package}"

      @generated_package_map = {} unless @generated_package_map

      place = @generated_package_map[package]
      if nil == place then
        place = ""
        @generated_package_map[package] = place
      end
      return place
    end

    def generate(directory_name, params={:verbose => false}, &eval_context)
      if directory_name then
        FileUtils.mkdir_p(directory_name) unless File.exist?(directory_name)
      end

      ensure_templates

      module_names = Set.new
      @elements_map.each do |ns, elements|
        elements.element_child.each do |element|
          module_names << element.package
          break
        end
      end

      lookup_element = {}
      @elements_map.each do |ns, elements|
        elements.element_child.each do |element|
          lookup_element[element.nstag] = element
        end
      end

      @templates.lookup_element = lookup_element

      @elements_map.each do |ns, elements|
        elements.element_child.each do |element|
          place = find_place(directory_name, element.package)

          @templates.element = element
          @templates.package_name = element.package

          if element.class_name == element.package then
            puts "ERROR: Class #{ element.package } is in a module with the same name -- this NOT going to work"
          elsif module_names.member?(element.class_name)
            puts "WARNING: a Class and a Module have the same name (#{ element.package }) -- this is highly unlikely to work"
          end

          @templates.child_modules(place)
        end
      end

      @elements_map.each do |ns, elements|
        elements.element_child.each do |element|
          place = find_place(directory_name, element.package)

          @templates.element = element
          @templates.package_name = element.package

          @templates.element_classes(place)
        end
      end

      @generated_package_map.each do |package_name, definition|
        package_name = "XamplAdHoc" unless package_name

        @templates.element = nil
        @templates.package_name = package_name
        @templates.options = @options

        @templates.required_packages = @required_packages[package_name] || {}

        @templates.place = definition

        package_definition = @templates.package

        if directory_name then
          output_filename = File.join(directory_name, "#{package_name}.rb")
          puts "WRITE TO FILE: #{output_filename}"
          #puts package_definition
          File.open(output_filename, "w") do |file|
            file.puts package_definition
          end
        end
        if block_given? then
          package_name = "XamplAdHoc" unless package_name
          puts "EVALUATE: #{package_name}"
          eval_context.call(package_definition, package_name)
        end
      end

      report_elements if params[:verbose]
    end

    def report_elements
      @elements_map.each_value do |elements|
        puts elements.pp_xml
      end
    end

    def print_elements(base_filename, print_options=nil)
      return unless base_filename
      return unless print_options
      return if 0 == print_options.size

      root = Elements.new
      @elements_map.each_value do |elements|
        elements.element_child.each do |element|
          root.children << element
        end
      end

      print_options.each do | print_option |
        case print_option
          when :schema then
            File.open("#{base_filename}.xml", "w") do |out|
              root.pp_xml(out)
            end
          when :graphml then
            graphml_out = GraphMLOut.new(@elements_map)
            graphml_out.write_graph_ml(base_filename)
          when :yuml then
            yuml_out = YUMLOut.new(@elements_map)
            yuml_out.write_yuml(base_filename)
        end
      end
    end

    def go(args, &eval_context)
      options = args[:options]
      if options then
        @options = options
      end

      strings = args[:strings]
      if strings then
        comprehend_from_strings(strings)
      end

      filenames = args[:filenames]
      if filenames then
        comprehend_from_files(filenames)
      end

      directory = args[:directory]
      if directory then
        generate_to_directory(directory, args)
      else
        generate_and_eval(args) do |module_definition, name|
          yield(module_definition, name)
        end
      end
    end

    def generate_to_directory(directory_name, params={:verbose => false})
      analyse
      return generate(directory_name, params)
    end

    def generate_and_eval(params={:verbose => false}, &eval_context)
      analyse
      return generate(nil, params, &eval_context)
    end

    def Generator.choose_names(original_name, attr_prefix="_", attr_suffix="_")

#      name = original_name.gsub(/[^a-zA-Z_]+/, "_")

      # NOTE (2009-04-16) -- if tag starts with a number, prefix it with an 'x'
      name = original_name.sub(/^([0-9])/) { | m | "x" + m }
      name = name.gsub(/[^a-zA-Z0-9_]+/, "_")


      attr_name = name.gsub(/[A-Z]+/, "_\\&")
      attr_name.gsub!(/__+/, "_")
      attr_name = attr_name[1..-1] if "_"[0] == attr_name[0]
      attr_name.downcase!

      name.gsub!(/[A-Z]/, "_\\&")
      name.gsub!(/__+/, "_")
      class_name = ""
      #name.each("_") do |chunk|
      name.split("_").each do |chunk|
        class_name << chunk.capitalize
      end
      class_name.gsub!("_", "")

      return class_name, attr_name
    end

    def print_stats
      count = 0
      @elements_map.each do |ns, elements|
        count += elements.element_child.size
        printf("namespace: %s, element: %d\n", ns, elements.element_child.size)
      end
      printf("counts of:: namespace: %d, element: %d\n", @elements_map.size, count)
      @elements_map.each do |ns, elements|
        puts elements.pp_xml
      end
    end
  end

  class Options
    def resolve(namespace, pkg="XamplAdHoc", preferred_prefix=nil)
      if (namespace.kind_of?(Array)) then
        namespace.each do |ns, prefix|
          self.new_resolve do |resolver|
            resolver.pkg = pkg
            resolver.namespace = ns
            resolver.preferred_prefix = prefix
          end
        end
      else
        self.new_resolve do |resolver|
          resolver.pkg = pkg
          resolver.namespace = namespace
          resolver.preferred_prefix = preferred_prefix
        end
      end
    end
  end

  class ChildElement
    def find_element(map)
      elements = map[self.namespace]
      return elements.element[self.element_name]
    end
  end

  class Element
    def found_text_content
      self.has_content = true
    end

    def analyse(options)
      is_empty, is_simple, is_data, is_mixed = false

      class_name, attribute_name = Generator.choose_names(@name)
      @class_name = class_name unless @class_name
      @attribute_name = attribute_name unless @attribute_name

      no_children = (0 == @child_element_child.size)

      unless @kind then
        if no_children then
          is_simple = @has_content
          is_empty = !is_simple
        else
          is_mixed = @has_content
          is_data = !@has_content
        end

        # this isn't a very strong piece of information, can't do much about it.
        #attribute_like = ((0 == @attribute_child.size) and is_simple)

        if    is_empty  then
          @kind = "empty"
        elsif is_simple then
          @kind = "simple"
        elsif is_data   then
          @kind = "data"
        elsif is_mixed  then
          @kind = "mixed"
        else
          throw "no kind determined" # this should be impossible
        end
      end

      unless self.indexed_by_attr then
        attribute_child.each do |attribute|
          aname_orig = attribute.name
          class_name, aname = Generator.choose_names(aname_orig)
          attribute.name = aname
          attribute.tag_name = aname_orig

          options.index_attribute_child.each do |iattr|
            if aname == iattr.name then
              self.indexed_by_attr = aname
              self.persisted = iattr.persisted
              break
            end
          end
        end

        if self.persisted then
          attribute = Attribute.new
          attribute.name = 'scheduled_for_deletion_at'
          attribute.tag_name = 'scheduled-for-deletion-at'
          attribute.namespace = nil
          self.add_attribute(attribute)
        end

      end
    end
  end

  def XamplGenerator.from_command_line(options=nil)
    opts = GetoptLong.new(
            ["--options", "-o", GetoptLong::REQUIRED_ARGUMENT],
            ["--elements", "-e", GetoptLong::REQUIRED_ARGUMENT],
            ["--gen:options", "-O", GetoptLong::OPTIONAL_ARGUMENT],
            ["--gen:elements", "-E", GetoptLong::OPTIONAL_ARGUMENT],
            ["--directory", "-d", GetoptLong::REQUIRED_ARGUMENT],
            ["--help", "-h", GetoptLong::NO_ARGUMENT],
            ["--version", "-v", GetoptLong::NO_ARGUMENT]
    )

    write_options = nil
    write_elements = nil
    directory = File.join(".", "tmp")

    opts.each do |opt, arg|
      case opt
        when "--help" then
          puts "--help, -h          :: this help message"
          puts "--options, -o       :: xml file seting the generation options"
          puts "--elements, -e      :: xml file providing a hint 'schema' (very optional)"
          puts "--gen:options, -O   :: write an xml file describing the options used (default gen-options.xml)"
          puts "--gen:elements, -E  :: write an xml file describing the 'schema' (default gen-elements.xml)"
          puts "--directory, -o     :: where to write the generated files (default #{directory})"
          puts "--version, -o       :: what version of xampl is this?"
          exit
        when "--version" then
          puts "version 0.0.0"
          exit
        when "--directory"
          directory = arg
        when "--options"
          puts "sorry, cannot read options yet"
        when "--elements"
          puts "sorry, cannot read elements yet"
        when "--gen:options"
          write_options = (arg and (0 < arg.length)) ? arg : "gen-options.xml"
        when "--gen:elements"
          write_elements = (arg and (0 < arg.length)) ? arg : "gen-elements.xml"
        else
          puts "  #{opt} #{arg}"
      end
    end

    puts "write options to: #{write_options}" if write_options
    puts "write elements to: #{write_elements}" if write_elements
    puts "write generated code to: #{directory}" if directory

    generator = Generator.new(options)

    filenames = []
    ARGV.each do |name|
      filenames << name
    end

    if 0 < filenames.length then
      generator.comprehend_from_files(filenames)
      generator.generate_to_directory(directory)

      generator.print_elements(write_elements) if write_elements
    end
  end
end
