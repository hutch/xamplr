require 'fileutils'
require 'set'

module XamplGenerator

  class GraphMLOut

    def initialize(elements_map)
      @elements_map = elements_map
    end

    def generate_class_nodes(element, include_mixins)

      node = @element_to_node_map[element.nstag]

      class_name = "#{ element.package }::#{ element.class_name }"
      mixin_name = "#{ element.package }::#{ element.class_name }"

      if element.persisted then
        write_entity_node(node, class_name, element.kind)
      else
        write_internal_node(node, class_name, element.kind)
      end

      if include_mixins then
        mixin_node = @mixed_in[element.nstag]
        #puts "#{ element.nstag } => #{ node }, mixin: [#{ mixin_node }]"
        if mixin_node then
          write_mixin_node(mixin_node, class_name)
        end
      end
#      puts "NODE #{ node } #{ class_name }"
      #      puts "NODE #{ mixin_node } #{ mixin_name }"
    end

    def generate_edges(element, include_mixins)
      # for each child, generate an entity-ref or internal-ref edge
      # for each child, generate a mixin-ref edge

      return if ignore_package(element.package)

      element.child_element_child.each do | celement |
        next if ignore_package(celement.package)

        cnstag = "{{#{ celement.namespace }}}#{ celement.element_name }"

        referenced_element = @ns_to_element_map[ cnstag ]
        next unless referenced_element

        this_node = @element_to_node_map[ element.nstag ]

        other_node = @element_to_node_map[ cnstag ]
        other_mixin = @mixed_in[ cnstag ]

        if referenced_element.persisted then
          @current_edge += 1
          write_entity_ref_edge(@current_edge, this_node, other_node)
#          puts "ER EDGE #{ @current_edge }, #{ this_node } --> #{ other_node } :: #{ element.class_name } --> #{ referenced_element.class_name }"
        else
          @current_edge += 1
          write_internal_ref_edge(@current_edge, this_node, other_node)
#          puts "IR EDGE #{ @current_edge }, #{ this_node } --> #{ other_node } :: #{ element.class_name } --> #{ referenced_element.class_name }"
        end
        if include_mixins then
          @current_edge += 1
          write_mixin_ref_edge(@current_edge, this_node, other_mixin)
          #        puts "MI EDGE #{ @current_edge }, #{ this_node } --> #{ other_mixin } :: #{ element.class_name } --> #{ referenced_element.class_name }"
        end
      end
    end

    def ignore_package(package)
      return true if @excluded_packages.member?(package)
      return false if @included_packages.nil?
      return true unless @included_packages.member?(package)
      return false
    end

    def write_graph_ml(base_filename, excluded_packages=[ ], included_packages=nil, include_mixins=true)
      filename = "#{base_filename}.graphml"

      @excluded_packages = Set.new(excluded_packages)
      @included_packages = included_packages ? Set.new(included_packages) : nil

      @element_to_node_map = {}
      @ns_to_element_map = {}
      @element_to_child_element_map = {}
      @mixed_in = {}

      nodes = 0
      edges = 0
      mixins = 0

      @elements_map.each_value do |elements|
        elements.element_child.each do |element|
          next if ignore_package(element.package)
          nodes += 1

          @element_to_node_map[element.nstag] = nodes
          @ns_to_element_map[element.nstag] = element
          @element_to_child_element_map[element.nstag] = map = {}

          element.child_element_child.each do | celement |
            edges += 1
            cnstag = "{{#{ celement.namespace }}}#{ celement.element_name }"
            map[cnstag] = edges
            unless @mixed_in.include?(cnstag) then
              mixins += 1
              @mixed_in[cnstag] = mixins
            end
          end
        end
      end

      @mixed_in.each do | k, v |
        @mixed_in[k] = v + nodes
      end

      #      puts "#{File.basename(__FILE__)}:#{__LINE__} #{ @element_to_node_map.inspect }"

      @reference_edges = edges

      File.open(filename, "w") do | out |
        @out = out

        if include_mixins then
          write_graphml_start(nodes + mixins, 2 * edges)
        else
          write_graphml_start(nodes, edges)
        end
        @elements_map.each_value do |elements|
          elements.element_child.each do |element|
            generate_class_nodes(element, include_mixins)
          end
        end

        @current_edge = 0
        @elements_map.each_value do |elements|
          elements.element_child.each do |element|
            generate_edges(element, include_mixins)
          end
        end
        write_graphml_end
#        puts "#{File.basename(__FILE__)}:#{__LINE__} EDGES:: predicted: #{ 2 * edges }, actual: #{ @current_edge }"
      end
      return nil
    end

    def write_entity_node(node, class_name, kind)
      @out << <<EOS
        <node id="n#{ node }">
            <data key="d0">
                <y:UMLClassNode>
                    <y:Geometry height="102.0"
                                width="111.0"
                                x="-5.5"
                                y="174.0"/>
                    <y:Fill color="#99CCFF"
                            transparent="false"/>
                    <y:BorderStyle color="#000000"
                                   type="line"
                                   width="2.0"/>
                    <y:NodeLabel alignment="center"
                                 autoSizePolicy="content"
                                 fontFamily="Dialog"
                                 fontSize="13"
                                 fontStyle="bold"
                                 hasBackgroundColor="false"
                                 hasLineColor="false"
                                 height="19.310546875"
                                 modelName="internal"
                                 modelPosition="c"
                                 textColor="#000000"
                                 visible="true"
                                 width="49.6904296875"
                                 x="30.65478515625"
                                 y="26.1328125">#{ class_name }
                    </y:NodeLabel>
                    <y:UML clipContent="true"
                           constraint=""
                           omitDetails="false"
                           stereotype="#{ kind }"
                           use3DEffect="false">
                        <!--y:AttributeLabel>bar
bar2</y:AttributeLabel>
                        <y:MethodLabel>foo()</y:MethodLabel-->
                    </y:UML>
                </y:UMLClassNode>
            </data>
            <data key="d1">UMLClass</data>
        </node>
EOS
    end

    def write_internal_node(node, class_name, kind)
      @out << <<EOS
        <node id="n#{ node }">
            <data key="d0">
                <y:UMLClassNode>
                    <y:Geometry height="102.0"
                                width="91.0"
                                x="4.5"
                                y="-1.0"/>
                    <y:Fill color="#CCFFCC"
                            transparent="false"/>
                    <y:BorderStyle color="#000000"
                                   type="line"
                                   width="1.0"/>
                    <y:NodeLabel alignment="center"
                                 autoSizePolicy="content"
                                 fontFamily="Dialog"
                                 fontSize="13"
                                 fontStyle="bold"
                                 hasBackgroundColor="false"
                                 hasLineColor="false"
                                 height="19.310546875"
                                 modelName="internal"
                                 modelPosition="c"
                                 textColor="#000000"
                                 visible="true"
                                 width="39.83251953125"
                                 x="25.583740234375"
                                 y="26.1328125">#{ class_name }
                    </y:NodeLabel>
                    <y:UML clipContent="true"
                           constraint=""
                           omitDetails="false"
                           stereotype="#{ kind }"
                           use3DEffect="false">
                        <!--y:AttributeLabel>bar</y:AttributeLabel>
                        <y:MethodLabel>foo()</y:MethodLabel-->
                    </y:UML>
                </y:UMLClassNode>
            </data>
            <data key="d1">UMLClass</data>
        </node>
EOS
    end

    def write_mixin_node(node, class_name)
      @out << <<EOS
        <node id="n#{ node }">
            <data key="d0">
                <y:UMLClassNode>
                    <y:Geometry height="102.0"
                                width="136.0"
                                x="-18.0"
                                y="349.0"/>
                    <y:Fill color="#FFCC99"
                            transparent="false"/>
                    <y:BorderStyle color="#000000"
                                   type="line"
                                   width="1.0"/>
                    <y:NodeLabel alignment="center"
                                 autoSizePolicy="content"
                                 fontFamily="Dialog"
                                 fontSize="13"
                                 fontStyle="bold"
                                 hasBackgroundColor="false"
                                 hasLineColor="false"
                                 height="19.310546875"
                                 modelName="internal"
                                 modelPosition="c"
                                 textColor="#000000"
                                 visible="true"
                                 width="110.818359375"
                                 x="12.5908203125"
                                 y="26.1328125">#{ class_name }
                    </y:NodeLabel>
                    <y:UML clipContent="true"
                           constraint=""
                           omitDetails="false"
                           stereotype="mixin"
                           use3DEffect="false">
                        <!--y:AttributeLabel></y:AttributeLabel>
                        <y:MethodLabel></y:MethodLabel-->
                    </y:UML>
                </y:UMLClassNode>
            </data>
            <data key="d1">UMLClass</data>
        </node>
EOS
    end

    def write_entity_ref_edge(edge, class_node, external_node)
      @out << <<EOS
        <edge id="e#{ edge }"
              source="n#{ class_node }"
              target="n#{ external_node }">
            <data key="d2">
                <y:PolyLineEdge>
                    <y:Path sx="0.0"
                            sy="0.0"
                            tx="0.0"
                            ty="0.0"/>
                    <y:LineStyle color="#000000"
                                 type="line"
                                 width="2.0"/>
                    <y:Arrows source="none"
                              target="short"/>
                    <y:EdgeLabel alignment="center"
                                 distance="2.0"
                                 fontFamily="Dialog"
                                 fontSize="12"
                                 fontStyle="plain"
                                 hasBackgroundColor="false"
                                 hasLineColor="false"
                                 height="4.0"
                                 modelName="six_pos"
                                 modelPosition="tail"
                                 preferredPlacement="anywhere"
                                 ratio="0.5"
                                 textColor="#000000"
                                 visible="true"
                                 width="4.0"
                                 x="30.000732421875"
                                 y="2.0"></y:EdgeLabel>
                    <y:BendStyle smoothed="false"/>
                </y:PolyLineEdge>
            </data>
            <data key="d3">UMLuses</data>
        </edge>
EOS
    end

    def write_internal_ref_edge(edge, class_node, internal_node)
      @out << <<EOS
        <edge id="e#{ edge }"
              source="n#{ class_node }"
              target="n#{ internal_node }">
            <data key="d2">
                <y:PolyLineEdge>
                    <y:Path sx="0.0"
                            sy="0.0"
                            tx="0.0"
                            ty="0.0"/>
                    <y:LineStyle color="#000000"
                                 type="line"
                                 width="1.0"/>
                    <y:Arrows source="none"
                              target="short"/>
                    <y:EdgeLabel alignment="center"
                                 distance="2.0"
                                 fontFamily="Dialog"
                                 fontSize="12"
                                 fontStyle="plain"
                                 hasBackgroundColor="false"
                                 hasLineColor="false"
                                 height="4.0"
                                 modelName="six_pos"
                                 modelPosition="tail"
                                 preferredPlacement="anywhere"
                                 ratio="0.5"
                                 textColor="#000000"
                                 visible="true"
                                 width="4.0"
                                 x="2.0"
                                 y="-38.529541015625"></y:EdgeLabel>
                    <y:BendStyle smoothed="false"/>
                </y:PolyLineEdge>
            </data>
            <data key="d3">UMLuses</data>
        </edge>
EOS
    end

    def write_mixin_ref_edge(edge, class_node, mixin_node)
      @out << <<EOS
        <edge id="e#{ edge }"
              source="n#{ mixin_node }"
              target="n#{ class_node }">
            <data key="d2">
                <y:PolyLineEdge>
                    <y:Path sx="0.0"
                            sy="0.0"
                            tx="0.0"
                            ty="0.0"/>
                    <y:LineStyle color="#000000"
                                 type="line"
                                 width="1.0"/>
                    <y:Arrows source="white_delta"
                              target="none"/>
                    <y:EdgeLabel alignment="center"
                                 distance="2.0"
                                 fontFamily="Dialog"
                                 fontSize="12"
                                 fontStyle="plain"
                                 hasBackgroundColor="false"
                                 hasLineColor="false"
                                 height="4.0"
                                 modelName="six_pos"
                                 modelPosition="tail"
                                 preferredPlacement="anywhere"
                                 ratio="0.5"
                                 textColor="#000000"
                                 visible="true"
                                 width="4.0"
                                 x="2.0"
                                 y="34.529541015625"></y:EdgeLabel>
                    <y:BendStyle smoothed="false"/>
                </y:PolyLineEdge>
            </data>
            <data key="d3">UMLinherits</data>
        </edge>
EOS
    end

    def write_graphml_start(nodes, edges)
      @out << <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns/graphml"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xmlns:y="http://www.yworks.com/xml/graphml"
         xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns/graphml http://www.yworks.com/xml/schema/graphml/1.0/ygraphml.xsd">
    <key for="node"
         id="d0"
         yfiles.type="nodegraphics"/>
    <key attr.name="description"
         attr.type="string"
         for="node"
         id="d1"/>
    <key for="edge"
         id="d2"
         yfiles.type="edgegraphics"/>
    <key attr.name="description"
         attr.type="string"
         for="edge"
         id="d3"/>
    <key for="graphml"
         id="d4"
         yfiles.type="resources"/>
    <graph edgedefault="directed"
           id="G"
           parse.edges="#{ edges }"
           parse.nodes="#{ nodes }"
           parse.order="free">
EOS
    end

    def write_graphml_end
      @out << <<EOS
    </graph>
    <data key="d4">
        <y:Resources/>
    </data>
</graphml>
EOS
    end

  end
end
