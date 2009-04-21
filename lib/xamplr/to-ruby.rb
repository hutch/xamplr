
module Xampl

  class RubyPrinter

    $USE_A_PROC = false

    def initialize(mentions=nil)
      @obj_count = 0
      @map = {}
      @lookup_map={}
      @mentions = mentions
    end

    def show_attributes(thing, name, depth)
      return "" unless thing.attributes

      out = ""
      indent = "    " + ("  " * depth)

      if thing.persist_required and (1 < depth)
        accessor = thing.indexed_by
        value = thing.get_the_index
        if value then
          out << indent << "#{name}.#{accessor} = #{value.inspect}\n"
        end
      else
        thing.attributes.each do |attribute|
          value = thing.instance_variable_get(attribute[0])

          if value then
            if value.kind_of?(XamplObject) then
              vname = "root_#{@obj_count += 1}"
              out << to_ruby_as_attr(value, depth, vname)
              out << indent << "#{name}.instance_variable_set(:#{attribute[0]}, #{vname})\n"
            else
              out << indent << "#{name}.instance_variable_set(:#{attribute[0]}, #{value.inspect})\n"
            end
          end
        end
      end
      return out
    end

    def show_children_tree(thing, name, depth)
      out = ""
      indent = "    " + ("  " * depth)

      if thing.persist_required and (1 < depth) then
        return out << indent << "#{name}.load_needed = true\n"
      end

      if (!thing.kind_of? XamplWithMixedContent) and
              (!thing.kind_of? XamplWithoutContent) and
              thing._content then
        out << indent << "#{name} << #{thing._content.inspect}\n"
      end
      thing.children.each do |child|
        if child.kind_of? XamplObject then
          cname = "v_#{child.safe_name}_#{@obj_count += 1}"

          cout = ""
          cout << show_attributes(child, cname, 1 + depth)
          cout << show_children_tree(child, cname, 1 + depth)

          if 0 < cout.size then
            out << indent << "#{name} << #{child.class.to_s}.new { | #{cname} |\n"
            out << cout
            out << indent << "}\n"
          else
            out << indent << "#{name} << #{child.class.to_s}.new\n"
          end
        else
          out << indent << "#{name} << #{child.inspect}\n"
        end
      end
      return out
    end

    def show_attributes_flat(thing, depth)
      return "" unless thing.attributes

      out = ""

      if thing.persist_required and (1 < depth)
        accessor = thing.indexed_by

        value = thing.get_the_index
        if value then
          out << "      " << "xampl.#{accessor} = #{value.inspect}\n"
        end
      else
        thing.attributes.each do |attribute|
          value = thing.instance_variable_get(attribute[0])

          if value then
            out << "      " << "xampl.instance_variable_set(:#{attribute[0]}, #{value.inspect})\n"
          end
        end
      end
      return out
    end

    def show_children_flat(thing, name, depth)
      out = ""

      thing.children.each do |child|
        if child.kind_of? XamplObject and (nil == @map[child]) then
          cname = "v_#{child.safe_name}_#{@obj_count += 1}"

          @map[child] = cname

          cout = ""
          cout << show_attributes_flat(child, 1 + depth)

          if 0 < cout.size then
            if child.persist_required then
              out << "    " << "#{cname} = #{child.class.to_s}['#{child.get_the_index}']\n"
              @mentions << child if @mentions
            else
              out << "    " << "#{cname} = #{child.class.to_s}.new { | xampl |\n"
              out << cout
              out << "    " << "}\n"
            end
          else
            out << "    " << "#{cname} = #{child.class.to_s}.new\n"
          end
          out << show_children_flat(child, cname, 1 + depth) unless child.persist_required
        end
      end
      return out
    end

    def show_children_stitch_start(thing, depth)
      @lookup_map.merge!(@map)
      return show_children_stitch(thing, depth)
    end

    def show_children_stitch(thing, depth)
      out = ""

      return out if thing.persist_required and (0 < depth)

      name = @map[thing]
      if name then
        @map.delete(thing)
      else
        return out
      end

      if (!thing.kind_of? XamplWithMixedContent) and
              (!thing.kind_of? XamplWithoutContent) and
              thing._content then
        out << "    " << "#{name} << #{thing._content.inspect}\n"
      end
      thing.children.each do |child|
        if child.kind_of? XamplObject then
          out << "    " << "#{name} << #{@lookup_map[child]}\n"
        else
          out << "    " << "#{name} << #{child.inspect}\n"
        end
      end
      thing.children.each do |child|
        if child.kind_of? XamplObject then
          out << show_children_stitch(child, 1 + depth)
        end
      end
      return out
    end

    def to_ruby(thing, depth=0, name="root")
      thing.accessed

      @obj_count = 0
      @map = {}
      @lookup_map={}

      @map[thing] = name

      if $USE_A_PROC then
        return %Q{
module XamplRubyDefinition
  @@proc = Proc.new { | target |
    #{name} = target ? target : #{thing.class.to_s}.new
#{show_attributes(thing, name, depth)}
        #{show_children_flat(thing, name, depth)}
        #{show_children_stitch_start(thing, depth)}
        #{name}
  }
end
}
      else
        return %Q{
module XamplRubyDefinition
  def XamplRubyDefinition.build_it(target)
    #{name} = target ? target : #{thing.class.to_s}.new
#{show_attributes(thing, name, depth)}
        #{show_children_flat(thing, name, depth)}
        #{show_children_stitch_start(thing, depth)}
        #{name}
  end
end
}
      end
    end

    def to_ruby_as_attr(thing, depth, name)
      thing.accessed

      @map[thing] = name

      return %Q{
      #{name} = #{thing.class.name}.new
#{show_attributes(thing, name, depth)}
      #{show_children_flat(thing, name, depth)}
      #{show_children_stitch_start(thing, depth)}
      }
    end
  end
end
