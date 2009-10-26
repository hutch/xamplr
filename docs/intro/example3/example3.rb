require 'greeter'
require 'greeting'

##include Example3 -- nope, not this time

Xampl.transaction("example3") do
  greeter = Example3::Greeter.new

  greeting1 = Example3::Greeting.new('has-name')
  greeting1.content = "Hello $$$, how are you?"
  greeter << greeting1

  greeter.new_who.name = 'world'
  greeter.new_who.name = 'there'

  greeting2 = greeter.new_greeting('no-name')
  greeting2.content = "Hello hello? Someone there?"

  greeter.new_who

  puts greeter.to_xml
  puts greeter.pp_xml

  puts "\nAnd now extend our greetings..."

  greeter.extend_greetings

  puts "\nwriting the xml representation of our greeter..."
  File.open('greeter.xml', 'w') { |f| f.write greeter.to_xml }
end
