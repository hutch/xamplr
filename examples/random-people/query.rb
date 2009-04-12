$LOAD_PATH.unshift("../../../xamplr-pp")
$LOAD_PATH.unshift("../../xamplr")
$LOAD_PATH.unshift("xampl_generated_code")

require 'RandomPeople'
require 'people'

Xampl.set_default_persister_kind(:tokyo_cabinet)
#Xampl.set_default_persister_format(:xml_format)
Xampl.set_default_persister_format(:ruby_format)

module RandomPeople

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

  5.times do
    start_query_at = Time.now
    found1 = Xampl.transaction("random-people") do
      Xampl.query do | q |
        q.add_condition('city', :equals, 'TORONTO')
        q.add_condition('email', :ends_with, 'dodgit.com')

        q.order_by('surname', :strasc)
      end
    end

    start_find_at = Time.now
    found2 = Xampl.transaction("random-people") do
      Xampl.find_xampl do | q |
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
#        q.add_condition('email', :ends_with, 'dodgit.com')

#        q.setlimit(10, 10)

        q.order_by('surname', :strasc)
      end
    end
    done = Time.now

    #  found1.each do | person_meta |
    #    puts "surname: #{ person_meta['surname']}, given: #{ person_meta['xampl'].given_name }"
    #  end
    puts "found:: query #{ found1.size }, find_xampl: #{ found2.size }, find_pids: #{ found3.size }"
    puts "query in: #{ start_find_at - start_query_at }, find_xampl in: #{ start_find_pids_at - start_find_at }, pids in: #{ done - start_find_pids_at}\n"
  end
end
