require 'fastercsv'
require 'xampl_generated_code/RandomPeople'
require 'people'
require 'settings'

module RandomPeople

  class BatchLoadUsers

    attr_accessor :random_names, :created_addresses, :shared_addresses

    def load_names(iter)
      inner_start = Time.now
      commit_total = 0
      commit_start = 0
      base = (1 + iter) * self.random_names.size

      random_names.each_with_index do | row, i |
        Xampl.transaction("random-people") do
          person_pid = "person-#{ base + i }"
          person = Person.new(person_pid)

          person.given_name = row[0]
          person.surname = row[1]
          person.email = row[6]
          person.phone = row[7]

          addresses = Address.find_by_query do | q |
            q.add_condition('street-address', :equals, row[2])
            q.add_condition('postal-code',    :equals, row[5])
          end

          address = addresses.first
          if address then
            person << address
            self.shared_addresses += 1
          else
            address = person.new_address("address-#{ person_pid }")
            address.street_address = row[2]
            address.city = row[3]
            address.state = row[4]
            address.postal_code = row[5]
            self.created_addresses += 1
          end

          commit_start = Time.now
        end
        commit_total += (Time.now - commit_start)
        puts "total: #{ commit_total }, iter: #{ i } --> #{ i / commit_total }/s" if 0 == (i % 1000)
      end
      done_at = Time.now
      total_time = done_at - inner_start
      puts "iter: #{ iter } in total: #{ total_time }, insert: #{ total_time - commit_total }, commit: #{ commit_total }"
    end

    def run
      start_at = Time.now

      self.random_names = FasterCSV.read("random-names.csv")

      parsed_at = Time.now

      base = 0
      self.created_addresses = 0
      self.shared_addresses = 0

      10.times do | iter |
        load_names(iter)
      end

      processed_at = Time.now

      puts "parsed in #{ parsed_at - start_at }, processed in: #{ processed_at - parsed_at }"
      puts "   created addresses: #{ created_addresses }, shared: #{ shared_addresses }"
    end

  end

  BatchLoadUsers.new.run

end
