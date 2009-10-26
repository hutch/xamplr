require 'greeter'
require 'greeting'

xml = <<EOX
<ex3:greeter xmlns:ex3='com.xampl.intro.example3'>
  <ex3:greeting id='has-name'>Hello $$$, how are you?</ex3:greeting>
  <ex3:who name='world'/>
  <ex3:who name='there'/>
  <ex3:greeting id='no-name'>Hello hello? Someone there?</ex3:greeting>
  <ex3:who/></ex3:greeter>
EOX

Xampl.transaction("example3") do
  greeter = Xampl.from_xml_string(xml)
  puts greeter.pp_xml

  puts "\nAnd now extend our greetings..."
  greeter.extend_greetings
end
