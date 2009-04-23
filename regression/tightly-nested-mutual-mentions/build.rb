
require 'setup'

module TestingStuff

# <stuff pid='' xmlns="http://xampl.com/stuff">
#         <parent pid=''>
#           <child pid=''>
#             <parent pid=''/>
#           </child>
#         </parent>
# </stuff>

    Xampl.transaction("stuff") do


      parent = Parent.new('parent1')
      child = Child.new('child1')

      parent << child
      child << parent

      puts "parent ---------------------------------------"
      puts parent.pp_xml
      puts "child ----------------------------------------"
      puts child.pp_xml
    end

end
