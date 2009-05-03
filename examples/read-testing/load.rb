$LOAD_PATH.unshift("xampl_generated_code")

require 'rubygems'
require 'Perf'
require 'settings'

module Perf

  count = 0
  root = nil
  $total_lines = 0

  srand( 12345 )

  def Perf.make_text(count)
    lines = 1 + rand(10)
    $total_lines += lines

    s = ""
    lines.times do | i |
      s << "this is a line for count: #{ count }, #{ i } of #{ lines } with scary stuff: <>&'\" ..."
    end
    return s
  end


  #<root pid=''
  #      xmlns="http://xampl.com/performance">
  #    <text pid=''
  #          size=''
  #          stuff=''>
  #        actual text
  #    </text>
  #</root>

  start_at = Time.now

  1.times do | outer |
    Xampl.transaction("random-people") do
      unless root then
        root = Root.new('root')
      end

      10000.times do | iter |

        count += 1

        text = root.new_text("text-#{ count }")
        text.stuff = "---<>&\"'---"
        text.content = make_text(count)

        #        puts "#{File.basename(__FILE__)}:#{__LINE__} #{ text.pp_xml }"

      end
    end

    puts "transaction #{ outer } ending... #{ Time.now - start_at } seconds"
#    puts "#{File.basename(__FILE__)}:#{__LINE__} #{ root.pp_xml }"
  end

  done_at = Time.now

  p "loaded #{ count }, total lines: #{ $total_lines }, in #{ done_at - start_at }"

end
