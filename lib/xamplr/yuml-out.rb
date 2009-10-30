require 'fileutils'
require 'set'

module XamplGenerator

  class YUMLOut

    def initialize(elements_map)
      @elements_map = elements_map
    end

    def generate_class_nodes(element, include_mixins)
      return if ignore_package(element.package)

      class_name = "#{ element.package }::#{ element.class_name }"
      mixin_name = "#{ element.package }::#{ element.class_name }"

      @class_by_nstag[element.nstag] = element
      @class_names_by_nstag[element.nstag] = class_name

      if element.persisted then
        write_entity_node(class_name, element.kind)
      else
        write_internal_node(class_name, element.kind)
      end

      if include_mixins then
        write_mixin_node(class_name)
      end
    end

    def generate_edges(element, include_mixins)
      return if ignore_package(element.package)

      element_name = @class_names_by_nstag[ element.nstag ]

      element.child_element_child.each do | celement |
        next if ignore_package(celement.package)

        celement_name = @class_names_by_nstag[ celement.name ]
        referenced_element = @class_by_nstag[ celement.name ]

        if referenced_element.persisted then
          write_entity_ref_edge(element_name, celement_name)
        else
          write_internal_ref_edge(element_name, celement_name)
        end
        if include_mixins then
          write_mixin_ref_edge(element_name, celement_name)
        end
      end
    end

    def ignore_package(package)
      return true if @excluded_packages.member?(package)
      return false if @included_packages.nil?
      return true unless @included_packages.member?(package)
      return false
    end

    def write_yuml(base_filename, excluded_packages=[ ], included_packages=nil, include_mixins=false)
      filename = "#{ base_filename }.yuml"

      @excluded_packages = Set.new(excluded_packages)
      @included_packages = included_packages ? Set.new(included_packages) : nil

      @class_names_by_nstag = {} # NOTE -- this is used by yuml!!
      @class_by_nstag = {} # NOTE -- this is used by yuml!!

      @initialise_output = true

      File.open(filename, "w") do | out |
        @out = out

        @elements_map.each_value do |elements|
          elements.element_child.each do |element|
            generate_class_nodes(element, include_mixins)
          end
        end

        @elements_map.each_value do |elements|
          elements.element_child.each do |element|
            generate_edges(element, include_mixins)
          end
        end
      end

      return nil
    end

    def new_statement
      if @initialise_output then
        @initialise_output = false
      else
        @out << ",\n"
      end
    end

    def write_entity_node(class_name, kind)
      new_statement
      @out << "[#{ class_name }{bg:red}]"
    end

    def write_internal_node(class_name, kind)
      new_statement
      @out << "[#{ class_name }{bg:blue}]"
    end

    def write_mixin_node(class_name)
      new_statement
      @out << "[#{ class_name }Mixin]"
    end

    def write_entity_ref_edge(class_node, external_node)
      new_statement
      @out << "[#{ class_node }]->[#{ external_node }]"
    end

    def write_internal_ref_edge(class_node, internal_node)
      new_statement
      @out << "[#{ class_node }]->[#{ internal_node }]"
    end

    def write_mixin_ref_edge(class_node, mixin_node)
      new_statement
      @out << "[#{ mixin_node }Mixin]^[#{ class_node }]"
    end
  end
end
