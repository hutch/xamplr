require 'xampl_generated_code/XamplAdHoc.rb'
require 'bad-idea.rb'

Xampl.set_default_persister_kind(:tokyo_cabinet)

Xampl.transaction("bad-idea") do
  car = Widget['the-car']
#  engine = Gadget['the-engine']
  car.value = 'ex-pinto'
end

