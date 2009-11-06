require 'xampl_generated_code/XamplAdHoc.rb'
require 'bad-idea.rb'

Xampl.set_default_persister_kind(:tokyo_cabinet)

puts "#{ __FILE__ }:#{ __LINE__ } [#{__method__}] *******************************************"
Xampl.transaction("bad-idea") do
  puts "#{ __FILE__ }:#{ __LINE__ } [#{__method__}] *******************************************"
  car = Widget['the-car']
  puts "#{ __FILE__ }:#{ __LINE__ } [#{__method__}] *******************************************"
#  engine = Gadget['the-engine']
  puts "#{ __FILE__ }:#{ __LINE__ } [#{__method__}] *******************************************"
  car.value = 'ex-pinto'
  puts "#{ __FILE__ }:#{ __LINE__ } [#{__method__}] *******************************************"
end
puts "#{ __FILE__ }:#{ __LINE__ } [#{__method__}] *******************************************"

