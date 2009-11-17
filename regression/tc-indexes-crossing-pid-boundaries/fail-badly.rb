require 'xampl_generated_code/XamplAdHoc.rb'
require 'fucking-bad-idea.rb'

Xampl.set_default_persister_kind(:tokyo_cabinet)

puts "#{ __method__} #{ __LINE__ }"
Xampl.transaction("bad-idea") do
puts "#{ __method__} #{ __LINE__ }"
  car = Widget['the-car']
puts "#{ __method__} #{ __LINE__ }"
#  engine = Gadget['the-engine']
puts "#{ __method__} #{ __LINE__ }"
  car.value = 'ex-pinto'
puts "#{ __method__} #{ __LINE__ }"
end
puts "#{ __method__} #{ __LINE__ }"

