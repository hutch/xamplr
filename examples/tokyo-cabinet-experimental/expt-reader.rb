require 'rubygems'

$LOAD_PATH.unshift("../../xamplr")
$LOAD_PATH.unshift("xampl_generated_code")

require 'TokyoCabinetExperimental'

Xampl.set_default_persister_kind(:tokyo_cabinet)
Xampl.set_default_persister_format(:xml_format)

module TokyoCabinetExperimental

  start = Time.now
  people = nil

  Xampl.transaction("setup") do
    people = People['people']
  end

  loop_start = Time.now

  total = 0
  people.person.each do | person |
    age = person.age.to_i
    total += age
  end

  done = Time.now

  puts "Total age: #{ total }"
  puts "done: #{ done - start }:: #{ loop_start - start} + #{ done - loop_start}"

end
