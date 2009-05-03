
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

  times = [0, 0]
  counts = [0, 0]

  10.times do | trial |
    found1 = []
    found2 = []
    found3 = []

    #<p:person email='Edelmira.K.Abshire@dodgit.com'
    #          given-name='Edelmira'
    #          phone='416-279-8804'
    #          pid='person-29944'
    #          surname='Abshire'
    #          xmlns:p='http://xampl.com/people'>
    #  <p:address city='TORONTO'
    #             pid='person-19944'
    #             postal_code='M1P 4W2'
    #             state='ON'
    #             street_address='4194 Borough Drive'/></p:person>


    all_people = nil
    people_inspected = 0
    start_at = Time.now

    people = Xampl.transaction("random-people") do
      addresses = Address.find_by_query do | q |
        q.add_condition('street-address', :equals, '4194 Borough Drive')
        q.add_condition('postal-code',    :equals, 'M1P 4W2')
      end

      all_people = Set.new
      people_inspected = 0

      addresses.each do | address |
        people = Person.find_by_query do | q |
          # TODO -- want to be able to find people by the address directly, e.g. address.find_by_citation/find_by_mention & find_by_reference
          q.add_condition('city',  :equals, address.city)
          q.add_condition('state', :equals, address.state)
        end

        people_inspected += people.size

        people.each do | person |
          all_people << person if person.address.first == address
        end
      end
    end

    done_at = Time.now
    puts "done in: #{ done_at - start_at }, #{ people_inspected } people inspected, #{ all_people.size } identified"
    times[0] += (done_at - start_at) if 0 < trial
    counts[0] += 1 if 0 < trial

    start_at = Time.now

    people = Xampl.transaction("random-people") do
      addresses = Address.find_by_query do | q |
        q.add_condition('street-address', :equals, '4194 Borough Drive')
        q.add_condition('postal-code',    :equals, 'M1P 4W2')
      end

      all_people = Set.new
      people_inspected = 0

      addresses.each do | address |
        people = Xampl.find_mentions_of(address)

        people_inspected += people.size
        all_people.merge(people)
      end
    end

    done_at = Time.now
    puts "done in: #{ done_at - start_at }, #{ people_inspected } people inspected, #{ all_people.size } identified"
    times[1] += (done_at - start_at) if 0 < trial
    counts[1] += 1 if 0 < trial
  end

  puts "0) total time: #{ times[0] }, count: #{ counts[0] }, average/s: #{ counts[0]/times[0]}"
  puts "1) total time: #{ times[1] }, count: #{ counts[1] }, average/s: #{ counts[1]/times[1]}"
end
