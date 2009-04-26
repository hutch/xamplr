$LOAD_PATH.unshift("xampl_generated_code")

require 'fastercsv'
require 'RandomPeople'
require 'people'

Xampl.set_default_persister_kind(:tokyo_cabinet)
Xampl.set_default_persister_format(:xml_format)
#Xampl.set_default_persister_format(:ruby_format)

module RandomPeople

  start_at = Time.now

  arr_of_arrs = FasterCSV.read("random-names.csv")

  parsed_at = Time.now

  #GivenName,Surname,StreetAddress,City,State,ZipCode,EmailAddress,TelephoneNumber
  #<people pid='' xmlns="http://xampl.com/people">
  #    <person pid=''
  #            given-name=''
  #            surname=''
  #            street-address=''
  #            city=''
  #            state=''
  #            postal-code=''
  #            email=''
  #            phone=''/>
  #</people>

  base = 0

  10.times do | iter |
    inner_start = Time.now
    Xampl.transaction("random-people") do

      people = People.new('people')

      base += arr_of_arrs.size

      arr_of_arrs.each_with_index do | row, i |
#        person = people.new_person("person-#{ base + i }")
        person = Person.new("person-#{ base + i }")

        person.given_name = row[0]
        person.surname = row[1]
        person.street_address = row[2]
        person.city = row[3]
        person.state = row[4]
        person.postal_code = row[5]
        person.email = row[6]
        person.phone = row[7]
      end
      puts "transaction ending..."
    end
    puts "iter: #{ iter } in #{ Time.now - inner_start }"
  end

  processed_at = Time.now

  p "parsed in #{ parsed_at - start_at }, processed in: #{ processed_at - parsed_at }"

end
