require 'xampl_generated_code/XamplAdHoc.rb'

Xampl.set_default_persister_kind(:tokyo_cabinet)

class Widget

  def Widget.indexed_attributes
    %w{ value gadget-value }
  end

  Xampl::TokyoCabinetPersister.add_lexical_indexs(Widget.indexed_attributes)

  def describe_yourself
    description = {
            'value' => self.value
    }

    secondary_descriptions = []

puts "#{ __method__} #{ __LINE__ }"
    self.gadget.each do | gadget |
puts "#{ __method__} #{ __LINE__ }"
      secondary_descriptions << {
              'gadget-value' => gadget.value
      }
puts "#{ __method__} #{ __LINE__ }"
      gadget.extra = 'fucking stupid change'
puts "#{ __method__} #{ __LINE__ }"
    end
puts "#{ __method__} #{ __LINE__ }"

    puts "\n\n\n\n#{ __FILE__ }:#{ __LINE__ } WIDGET(#{ self.pid })"
#    puts pp_xml
    puts "#{ __FILE__ }:#{ __LINE__ }     description: #{ description.inspect }"
    secondary_descriptions.each do | secondary |
      puts "#{ __FILE__ }:#{ __LINE__ }       secondary: #{ secondary.inspect }"
    end
    puts "\n\n\n"

    return description, secondary_descriptions
  end

end

