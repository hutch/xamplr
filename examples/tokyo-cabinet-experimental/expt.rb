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
      {
              'name' => self.name,
              'age' => self.age
      }
    end
  end

  people = nil
  n = 1000

  start = Time.now
  Xampl.transaction("setup") do
    people = People.new('people')
    jack = people.ensure_person('jack')
    jack.age = '0'
    jack.name = 'jack'
    jill = people.ensure_person('jill')
    jill.age = '0'
    jill.name = 'jill'

    (1..n).each do | i |
      person = people.ensure_person("person-#{i}")
      person.age = i.to_s
      person.name = "person-#{ i }"
    end
  end

  start_search = Time.now

  found = Xampl.transaction("setup") do
    puts ">>>>>> #{@@persister.class.name}"
    @@persister.query do | q |
      puts ">>>> #{ q.class.name }"
      q.add_condition('age', :numle, '50')
      q.order_by('age', :numasc)
    end
  end

  # found.each do | person |
  #   puts "person(#{person[:pk]}):: age: #{person['age']}"
  # end

  done = Time.now
  puts "done: #{ done - start }:: construct in: #{ start_search - start}, search in: #{ done - start_search} (#{ found.size } results)"
  puts "added: #{ n }, found: #{ found.size }"

  # puts people.pp_xml
end
