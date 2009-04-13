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

  1.times do
    found1 = []
    found2 = []
    found3 = []

    start = Time.now

    Xampl.transaction("random-people") do
      found1 = Xampl.find_pids do | q |
        q.add_condition('city', :equals, 'TORONTO')
        q.add_condition('surname', :equals, 'Smith')
      end

      found2 = Xampl.find_pids do | q |
        q.add_condition('city', :equals, 'LONDON')
        q.add_condition('surname', :equals, 'Smith')
      end

      found3 = Xampl.find_pids do | q |
        q.add_condition('city', :stror, 'TORONTO,LONDON')
        q.add_condition('surname', :equals, 'Smith')
      end
    end

    done = Time.now

    puts "INDEXED found(#{ done - start }):: TORONTO #{ found1.size }, LONDON: #{ found2.size }, TORONTO,LONDON: #{ found3.size }/#{ found1.size + found2.size }"

    start = Time.now

    Xampl.transaction("random-people") do
      found1 = Xampl.find_pids do | q |
        q.add_condition('city', :equals, 'TORONTO', true, true)
        q.add_condition('surname', :equals, 'Smith', true, true)
      end

      found2 = Xampl.find_pids do | q |
        q.add_condition('city', :equals, 'LONDON', true, true)
        q.add_condition('surname', :equals, 'Smith', true, true)
      end

      found3 = Xampl.find_pids do | q |
        q.add_condition('city', :stror, 'TORONTO,LONDON', true, true)
        q.add_condition('surname', :equals, 'Smith', true, true)
      end
    end

    done = Time.now

    puts "NOT INDEXED found(#{ done - start }):: TORONTO #{ found1.size }, LONDON: #{ found2.size }, TORONTO,LONDON: #{ found3.size }/#{ found1.size + found2.size }"
  end
end
