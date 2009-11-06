require 'xampl_generated_code/XamplAdHoc.rb'
require 'bad-idea.rb'

Xampl.set_default_persister_kind(:tokyo_cabinet)

Xampl.transaction("bad-idea") do
  car = Widget.new('the-car')
  car.value = "pinto"

  engine = car.new_gadget('the-engine')
  engine.value = 'guzzler'

  gas_tank = car.new_gadget('the-gas-tank')
  gas_tank.value = 'the burner'
end
