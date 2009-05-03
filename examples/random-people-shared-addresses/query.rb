
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

  5.times do
    found1 = []
    found2 = []
    found3 = []

    start_query_at = Time.now
    found1 = Xampl.transaction("random-people") do
      Xampl.query do | q |
        q.add_condition('city', :equals, 'TORONTO')
        q.add_condition('email', :ends_with, 'dodgit.com')

#        q.setlimit(10, 10)

        q.order_by('surname', :strasc)
      end
    end

    start_find_at = Time.now
    found2 = Xampl.transaction("random-people") do
      Person.find_by_query do | q |
        q.add_condition('city', :equals, 'TORONTO')
        q.add_condition('email', :ends_with, 'dodgit.com')

#        q.setlimit(10, 10)

        q.order_by('surname', :strasc)
      end
    end

    start_find_pids_at = Time.now

    found3 = Xampl.transaction("random-people") do
      Xampl.find_pids do | q |
        q.add_condition('city', :equals, 'TORONTO')
        q.add_condition('email', :ends_with, 'dodgit.com')

#        q.setlimit(10, 10)

        q.order_by('surname', :strasc)
      end
    end
    done = Time.now

    #  found1.each do | person_meta |
    #    puts "surname: #{ person_meta['surname']}, given: #{ person_meta['xampl'].given_name }"
    #  end

    puts
    puts "query    :: found: #{ found1.size }, in: #{ start_find_at - start_query_at }"
    puts "find     :: found: #{ found2.size }, in: #{ start_find_pids_at - start_find_at }"
    puts "find pids:: found: #{ found3.size }, in: #{ done - start_find_pids_at}"
  end
end
