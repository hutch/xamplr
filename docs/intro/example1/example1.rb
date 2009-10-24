
require 'xampl_generated_code/Example1.rb'

#module Example1

Xampl.transaction("setup") do
  h = Hello.new
  puts h.pp_xml
end

#end
