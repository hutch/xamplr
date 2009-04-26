
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
      parent = Parent['parent1']
      puts "parent has info: #{ parent.info }"
      child = parent.child.first
      puts "child has info: #{ child.info }"
    end

end
