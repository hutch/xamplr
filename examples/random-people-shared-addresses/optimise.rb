$LOAD_PATH.unshift("xampl_generated_code")

require 'RandomPeople'
require 'people'
require 'settings'

module RandomPeople

  start_opt = Time.now
  Xampl.transaction("random-people") do
    Xampl.optimise(:indexes_only => true)
#    Xampl.optimise
  end
  puts "optimised in #{ Time.now - start_opt}"

end
