module BenchScript

  def BenchScript.build
    return Thing.new{ | bt |
      bt.new_thing("thing") { | t |
        t.new_stuff.kind = "stuff1"
        t.new_description{ | d |
          d.kind = "desc1"
          d << "hello "
          d.new_emph.content = "there"
          d << "! How "
          d.new_emph.content = "are"
          d << " you?"
        }
      }
    }
  end
end



