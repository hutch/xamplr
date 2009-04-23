
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
      thing = Parent['parent1']
      #puts thing.pp_xml

      #thing = Child['child1']
      #puts thing.pp_xml
    end

end
