$LOAD_PATH.unshift("xampl_generated_code")

require 'set'
require 'fastercsv'
require 'RandomPeople'
require 'people'

Xampl.set_default_persister_kind(:tokyo_cabinet)
Xampl.set_default_persister_format(:xml_format)

module RandomPeople
  arr_of_arrs = FasterCSV.read("random-names.csv")

  surnames = Set.new
  cities = Set.new
  states = Set.new
  email_domains = Set.new

  arr_of_arrs.each do | row |
    surname = row[1]
    city = row[3]
    state = row[4]

    surnames << surname
    cities << city
    states << state

    email = row[6]
    domain = email.split("@")
    if 2 == domain.size then
      email_domains << domain[1]
    end

  end

  puts "surnames: #{ surnames.size }"
  puts "cities: #{ cities.size }"
  puts "states: #{ states.size }"
  puts "email_domains: #{ email_domains.size }"

  puts "STATES:"
  puts states.to_a.sort.inspect

  puts "EMAIL DOMAINS:"
  puts email_domains.to_a.sort.inspect

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

#  Xampl.transaction("random-people") do
#
#    people = People.new('people')
#
#    arr_of_arrs.each_with_index do | row, i |
#      person = people.new_person("person-#{ i }")
#      person.given_name = row[0]
#      person.surname = row[1]
#      person.street_address = row[2]
#      person.city = row[3]
#      person.state = row[4]
#      person.postal_code = row[5]
#      person.email = row[6]
#      person.phone = row[7]
#    end
#  end
#
#  processed_at = Time.now
#
#  p counts
#  p "parsed in #{ parsed_at - start_at }, counted in: #{ counted_at - parsed_at }, processed in: #{ processed_at - counted_at }"

end
