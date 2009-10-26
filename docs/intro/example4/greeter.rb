require 'xampl_generated_code/Example3.rb'

module Example3
  class Greeter
    def extend_greetings
      who.each do | who |
        if who.name then
          puts greeting['has-name'].extend_greeting(who.name)
        else
          puts greeting['no-name'].extend_greeting
        end
      end
    end
  end
end
