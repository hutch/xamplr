require 'xampl_generated_code/Example3.rb'

module Example3
  class Greeting
    def extend_greeting(name=nil)
      name ? content.gsub(/\$\$\$/){ name } : ''
    end
  end
end
