require 'rubygems'

$LOAD_PATH.unshift("../../xamplr")
$LOAD_PATH.unshift("xampl_generated_code")

require 'TokyoCabinetExperimental'

Xampl.set_default_persister_kind(:tokyo_cabinet)
Xampl.set_default_persister_format(:xml_format)

module TokyoCabinetExperimental

  start = Time.now
  found = Xampl.transaction("setup") do
    @@persister.query do | q |
      q.add_condition('age', :numle, '50')
      q.order_by('name', :strasc)
    end
  end
  query_done = Time.now

  total = 0
  found.each do | person_meta |
    total += person_meta['age'].to_i
  end

  meta_done = Time.now

  total1 = 0
  found.each do | person_meta |
    total1 += person_meta['xampl'].age.to_i
  end

  done = Time.now

  found.each do | person_meta |
    puts "name: #{ person_meta['name']}"
  end
  puts "found: #{ found.size }"
  puts "Total age: #{ total }, #{ total1 }"
  puts "done: #{ done - start }:: #{ query_done - start } + #{ meta_done - query_done } + #{ done - meta_done }"

end
