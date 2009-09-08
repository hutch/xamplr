require 'rubygems'
require 'xampl_generated_code/Hobbies'

Xampl.set_default_persister_kind(:tokyo_cabinet)
Xampl.set_default_persister_format(:xml_format)


module Hobbies

  class Hobby
    def Hobby.indexed_attributes
      %w{ hobby-name }
    end

    Xampl::TokyoCabinetPersister.add_lexical_indexs(Hobby.indexed_attributes)

#    puts "#{ __FILE__ }:#{ __LINE__ } lexical indexes: #{ Hobby.indexed_attributes.inspect }"

    def describe_yourself
      description = {
              'hobby-name' => self.name
      }

#      puts "#{ __FILE__ }:#{ __LINE__ } description: #{ description.inspect }"

      return description
    end
  end

  class Person
    def Person.indexed_attributes
      %w{ person-name person-hobby }
    end

    Xampl::TokyoCabinetPersister.add_lexical_indexs(Person.indexed_attributes)

#    puts "#{ __FILE__ }:#{ __LINE__ } lexical indexes: #{ Person.indexed_attributes.inspect }"

    def describe_yourself
      description = {
              'person-name' => self.name
      }

      additional_descriptions = []

      self.hobby.each do | hobby |
        additional_descriptions << {
                'person-hobby' => hobby.name
        }
      end

#      puts "#{ __FILE__ }:#{ __LINE__ } description: #{ description.inspect }, additional: #{ additional_descriptions.inspect }"

      return description, additional_descriptions
    end
  end

  start_at = Time.now.to_i

  repo_name = "hobbies-#{ start_at }"

  Xampl.transaction(repo_name) do

    (reading = Hobby.new('reading')).name = 'reading'
    (tv = Hobby.new('tv')).name = 'tv'
    (birds = Hobby.new('birds')).name = 'birds'

    (jack = Person.new('jack')).name = 'Jack'
    (jill = Person.new('jill')).name = 'Jill'

    jack << reading
    jack << tv

    jill << reading
    jill << birds
  end

  #  Xampl.transaction(repo_name) do
  #    jack = Person['jack']
  #    jill = Person['jill']
  #
  #    puts jack.pp_xml
  #    puts jill.pp_xml
  #  end

  Xampl.transaction(repo_name) do
    people = Person.find_by_query do | q |
      q.add_condition('person-name', :streq, 'Jill')
      q.order_by('person-name')
    end

    puts "#{ __FILE__ }:#{ __LINE__ } found #{ people.size } people named Jill"
    puts "#{ __FILE__ }:#{ __LINE__ } WRONG!! WRONG!! WRONG!! WRONG!! WRONG!! WRONG!! WRONG!! WRONG!!" unless 0 < people.size
  end

  #NOW... look for people with hobbies

  Xampl.transaction(repo_name) do
    people = Person.find_by_query do | q |
      q.add_condition('person-hobby', :streq, 'reading')
      q.order_by('person-name')
    end

    puts "#{ __FILE__ }:#{ __LINE__ } found #{ people.size } people with hobby 'reading'"
    people.each { | person | puts "#{ __FILE__ }:#{ __LINE__ }     #{ person.name }"}

    people = Person.find_by_query do | q |
      q.add_condition('person-hobby', :streq, 'birds')
      q.order_by('person-name')
    end

    puts "#{ __FILE__ }:#{ __LINE__ } found #{ people.size } people with hobby 'birds'"
    people.each { | person | puts "#{ __FILE__ }:#{ __LINE__ }     #{ person.name }"}
  end

  #NOW... change hobby of someone and search again

  Xampl.transaction(repo_name) do
    jack = Person['jack']
#    puts "#{ __FILE__ }:#{ __LINE__ } jack before: #{ jack.pp_xml }"
    jack.remove_hobby('reading')

    birds = Hobby['birds']
    jack << birds if birds
  end

  #NOW... look for people with hobbies

  Xampl.transaction(repo_name) do
    people = Person.find_by_query do | q |
      q.add_condition('person-name', :streq, 'Jack')
      q.order_by('person-name')
    end

    puts "#{ __FILE__ }:#{ __LINE__ } found #{ people.size } people with name 'Jack'"
    people.each { | person | puts "#{ __FILE__ }:#{ __LINE__ }     #{ person.name }"}

    people = Person.find_by_query do | q |
      q.add_condition('person-hobby', :streq, 'reading')
      q.order_by('person-name')
    end

    puts "#{ __FILE__ }:#{ __LINE__ } found #{ people.size } people with hobby 'reading'"
    people.each { | person | puts "#{ __FILE__ }:#{ __LINE__ }     #{ person.name }"}

    people = Person.find_by_query do | q |
      q.add_condition('person-hobby', :streq, 'birds')
      q.order_by('person-name')
    end

    puts "#{ __FILE__ }:#{ __LINE__ } found #{ people.size } people with hobby 'birds'"
    people.each { | person | puts "#{ __FILE__ }:#{ __LINE__ }     #{ person.name }"}

    found = Xampl.find_xampl do | q |
      q.add_condition('person-hobby', :streq, 'birds')
      q.order_by('person-name')
    end
    found.each_with_index do | xampl, i |
      puts "#{ __FILE__ }:#{ __LINE__ } Xampl.find_xampl(#{ i }) -- #{ xampl.name }"
    end

    found = Xampl.find_xampl do | q |
      q.add_condition('person-name', :streq, 'Jack')
      q.order_by('person-name')
    end
    puts "#{ __FILE__ }:#{ __LINE__ } FOUND: #{ found.size }"
    found.each_with_index do | xampl, i |
      puts "#{ __FILE__ }:#{ __LINE__ } Xampl.find_xampl(#{ i }) -- #{ xampl.name }"
    end

    found = Xampl.find_pids do | q |
       q.add_condition('person-hobby', :streq, 'birds')
       q.order_by('person-name')
     end
     found.each_with_index do | xampl, i |
       puts "#{ __FILE__ }:#{ __LINE__ } Xampl.find_pids(#{ i }) -- #{ xampl }"
     end

     found = Xampl.find_meta do | q |
      q.add_condition('person-hobby', :streq, 'birds')
      q.order_by('person-name')
    end
    found.each_with_index do | xampl, i |
      puts "#{ __FILE__ }:#{ __LINE__ } Xampl.find_meta(#{ i }) -- #{ xampl.inspect }"
    end

  end

  done_at = Time.now

  p "#{ __FILE__ }:#{ __LINE__ } ran in #{ done_at - start_at }"

end
