require 'xampl_generated_code/Example2.rb'

include Example2

class Hello
  def to_s
    "Hello #{ who ? who : 'hello?' }!"
  end
end

Xampl.transaction("example2") do
  h = Hello.new

  puts "haven't set the who attribute yet..."
  puts h.to_xml
  puts h

  h.who = 'world'

  puts "\nhave set the who attribute to 'world'..."
  puts h.to_xml
  puts h.pp_xml
  puts h

  h2 = Hello.new
  h2.who = 'there'

  all = [ h, h2 ]

  puts "\nthere are two Hello things now..."
  puts h
  puts h2

  puts "\nprint an array of the two Hello things..."
  puts all
  puts "\ninspect an array of the two Hello things..."
  puts all.inspect
end
