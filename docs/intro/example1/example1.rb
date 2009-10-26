require 'xampl_generated_code/XamplAdHoc.rb'

Xampl.transaction("example1") do
  h = HelloWorld.new
  puts h.to_xml
end
