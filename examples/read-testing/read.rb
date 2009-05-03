require 'rubygems'
require 'xampl_generated_code/Perf'
require 'settings'

module Perf

  count = 0
  root = nil
  $total_lines = 0

  #<root pid=''
  #      xmlns="http://xampl.com/performance">
  #    <text pid=''
  #          size=''
  #          stuff=''>
  #        actual text
  #    </text>
  #</root>

  start_at = Time.now

  Xampl.transaction("random-people") do
    root = Root['root']
  end
  root_at = Time.now
  puts "#{File.basename(__FILE__)}:#{__LINE__} Root read in #{ root_at - start_at}"

  root.text.each do | text |
    count += 1
  end

  #puts root.pp_xml

  looped_at = Time.now
  puts "#{File.basename(__FILE__)}:#{__LINE__} looped over #{ count } text in #{ looped_at - root_at } NO LOADING"

  count = 0
  total_lines = 0

  root.text.each do | text |
    content = text.content
#    puts "#{File.basename(__FILE__)}:#{__LINE__} content: [[#{ content }]]"
    total_lines += content.length() if content
    count += 1
  end

  done_at = Time.now

  puts "loaded #{ count }, total lines: #{ total_lines }, in #{ done_at - looped_at } seconds, total time: #{ done_at - start_at } seconds"

end
