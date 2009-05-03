
require 'xampl_generated_code/RandomPeople'
require 'people'
require 'settings'

module RandomPeople

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

  10.times do

    people = Xampl.transaction("random-people") do
      Person.find_by_query do | q |
        q.add_condition('city', :equals, 'TORONTO')
        q.add_condition('email', :ends_with, 'dodgit.com')

        q.order_by('surname', :strasc)
      end
    end

    first_person = people.first
    address = first_person.address.first

    start_at = Time.now

    people_at_address = Xampl.transaction("random-people") do
      Xampl.find_mentions_of(address)
    end

    done = Time.now
    puts "found #{ people_at_address.size } people at that address in: #{ done - start_at }, #{ people_at_address.size / (done - start_at) }/s"
#    people_at_address.each { | person | puts person.pp_xml }
  end
end
