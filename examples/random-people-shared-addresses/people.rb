
require 'xampl_generated_code/RandomPeople'

module RandomPeople

  class Person

    Xampl::TokyoCabinetPersister.add_lexical_indexs(%w{ surname city state email })

    def describe_yourself
      {
              'surname' => self.surname,
              'city' => self.address.first.city,
              'state' => self.address.first.state,
              'email' => self.email
      }
    end
  end

  class Address

    Xampl::TokyoCabinetPersister.add_lexical_indexs(%w{ street-address postal-code city state })

    def describe_yourself
      {
              'street-address' => self.street_address,
              'postal-code' => self.postal_code,
              'city' => self.city,
              'state' => self.state
      }
    end
  end

end

