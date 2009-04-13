$LOAD_PATH.unshift("../../../xamplr-pp")
$LOAD_PATH.unshift("../../xamplr")
$LOAD_PATH.unshift("xampl_generated_code")

require 'RandomPeople'
require 'people'

Xampl.set_default_persister_kind(:tokyo_cabinet)
#Xampl.set_default_persister_format(:xml_format)
Xampl.set_default_persister_format(:ruby_format)

module RandomPeople

  start_opt = Time.now
  Xampl.transaction("random-people") do
    Xampl.optimise(:indexes_only => true)
#    Xampl.optimise
  end
  puts "optimised in #{ Time.now - start_opt}"

end
