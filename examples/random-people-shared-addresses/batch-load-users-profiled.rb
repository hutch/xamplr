require 'fastercsv'
require 'xampl_generated_code/RandomPeople'
require 'people'
require 'settings'

require 'ruby-prof'

module RandomPeople

  class BatchLoadUsersProfiled

    attr_accessor :random_names, :created_addresses, :shared_addresses

    def load_names(iter)
      inner_start = Time.now
      commit_start = 0
      base = (1 + iter) * self.random_names.size

      Xampl.transaction("random-people") do

        random_names.each_with_index do | row, i |
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

        end
        puts "transaction ending..."
        commit_start = Time.now
      end
      done_at = Time.now
      puts "iter: #{ iter } in total: #{ done_at - inner_start }, insert: #{ commit_start - inner_start}, commit: #{done_at - commit_start}"
    end

    def run
      start_at = Time.now

      self.random_names = FasterCSV.read("random-names.csv")

      parsed_at = Time.now

      base = 0
      self.created_addresses = 0
      self.shared_addresses = 0

      2.times do | iter |
        if 1 == iter then
          RubyProf.start

          load_names(iter)

          result = RubyProf.stop
          printer = RubyProf::FlatPrinter.new(result)
          printer.print(STDOUT, 0)
        else
          load_names(iter)
        end
      end

      processed_at = Time.now

      puts "parsed in #{ parsed_at - start_at }, processed in: #{ processed_at - parsed_at }"
      puts "   created addresses: #{ created_addresses }, shared: #{ shared_addresses }"
    end

  end

  BatchLoadUsersProfiled.new.run

end
