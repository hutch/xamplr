require 'rubygems'

$LOAD_PATH.unshift("../../../xamplr-pp")
$LOAD_PATH.unshift("../../xamplr")
$LOAD_PATH.unshift("xampl_generated_code")

require 'TokyoCabinetExperimental'

Xampl.set_default_persister_kind(:tokyo_cabinet)
Xampl.set_default_persister_format(:xml_format)

module TokyoCabinetExperimental
  
  class Person
    def describe_yourself
      { 'age' => self.age }
    end
  end

people = nil

start = Time.now
Xampl.transaction("setup") do
# Xampl.transaction("setup", :filesystem) do
  people = People.new('people')
  jack = people.ensure_person('jack')
  jack.age = '0'
  jill = people.ensure_person('jill')
  jill.age = '0'
  
  (1..1000).each do | i |
    person = people.ensure_person("person-#{i}")
    person.age = i.to_s
  end
end

start_search = Time.now

found = Xampl.transaction("setup") do
  puts ">>>>>> #{@@persister.class.name}"
  @@persister.query do | q |
    puts ">>>> #{ q.class.name }"
    q.add_condition('age', :numle, '50')
    q.order_by('age', :numasc)
    q.no_pk(false)
  end
end
puts "found: #{ found.size }"

# found.each do | person |
#   puts "person(#{person[:pk]}):: age: #{person['age']}"
# end

done = Time.now
puts "done: #{ done - start }:: construct in: #{ start_search - start}, search in: #{ done - start_search} (#{ found.size } results)"

# puts people.pp_xml

end
