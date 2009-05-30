require 'fastercsv'
require 'xampl_generated_code/RandomPeople'
require 'people'
require 'settings'

module RandomPeople

  start_at = Time.now

  arr_of_arrs = FasterCSV.read("random-names.csv")

  parsed_at = Time.now

  #GivenName,Surname,StreetAddress,City,State,ZipCode,EmailAddress,TelephoneNumber

  #<people pid=''
  #        xmlns="http://xampl.com/people">
  #    <person pid=''
  #            given-name=''
  #            surname=''
  #            email=''
  #            phone=''>
  #        <address pid=''
  #                 street-address=''
  #                 city=''
  #                 state=''
  #                 postal-code=''/>
  #    </person>
  #</people>

  base = 0

  created_addresses = 0
  shared_addresses = 0

  10.times do | iter |
    inner_start = Time.now
    commit_start = 0

    Xampl.transaction("random-people") do

      base += arr_of_arrs.size

      arr_of_arrs.each_with_index do | row, i |
        person_pid = "person-#{ base + i }"
        person = Person.new(person_pid)

        person.given_name = row[0]
        person.surname = row[1]
        person.email = row[6]
        person.phone = row[7]

        addresses = Xampl.find_xampl do | q |
          q.add_condition('class', :equals, Address.name)

          q.add_condition('street-address', :equals, row[2])
          q.add_condition('postal-code',    :equals, row[5])
        end

        address = addresses.first
        if address then
          person << address
          shared_addresses += 1
        else
          address = person.new_address("address-#{ person_pid }")
          address.street_address = row[2]
          address.city = row[3]
          address.state = row[4]
          address.postal_code = row[5]
          created_addresses += 1
        end

      end
      puts "transaction ending..."
      commit_start = Time.now
    end
    done_at = Time.now
    puts "iter: #{ iter } in total: #{ done_at - inner_start }, insert: #{ commit_start - inner_start}, commit: #{done_at - commit_start}"
  end

  processed_at = Time.now

  p "parsed in #{ parsed_at - start_at }, processed in: #{ processed_at - parsed_at }"
  puts "   created addresses: #{ created_addresses }, shared: #{ shared_addresses }"

end
