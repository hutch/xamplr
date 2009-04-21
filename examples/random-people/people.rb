$LOAD_PATH.unshift("xampl_generated_code")

require 'RandomPeople'

#Xampl.set_default_persister_kind(:tokyo_cabinet)
#Xampl.set_default_persister_format(:xml_format)

module RandomPeople

  class Person

    Xampl::TokyoCabinetPersister.add_lexical_indexs(%w{ surname city state email })

    def describe_yourself
      {
              'surname' => self.surname,
              'city' => self.city,
              'state' => self.state,
              'email' => self.email
      }
    end
  end

end

