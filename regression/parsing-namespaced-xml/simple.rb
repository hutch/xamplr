
require 'xampl-generated-code/all.rb'

Xampl.set_default_persister_kind(:filesystem)

Xampl.transaction('repo') do 
  simple = Simple.new('xxxxx')
  simple.new_thing
  simple.new_thing
  simple.new_thing
end

Xampl.transaction('repo2') do 
  filename = 'repo/repo/Simple/xxxxx'
  xml = File.open(filename).read
  puts xml

  x = XamplObject.from_xml_string(xml)
  puts "now have a #{ x.class.name }"
end
