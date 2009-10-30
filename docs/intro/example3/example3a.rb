require 'greeter'
require 'greeting'

unless File.exists? "greeter.xml" then
  puts "run example3 before running this one"
  exit
end

xml = File.open("greeter.xml") { | f | f.read }

Xampl.transaction("example3") do
  greeter = Xampl.from_xml_string(xml)

  puts "\nAnd now extend our greetings..."
  greeter.extend_greetings
end
