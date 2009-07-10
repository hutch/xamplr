module Xampl

  class Visitor
    attr_accessor :no_children, :no_siblings, :done

    def initialize
      reset
    end

    def reset
      @no_children = false
      @no_siblings = false
      @done = false

      @short_circuit = false

      @visited = {}
      @visiting = {}

      @revisiting = false
      @cycling = false
    end

    def cycle(xampl)
      return false
    end

    def revisit(xampl)
      return false
    end

    def short_circuit
    end

    def method_missing(symbol, *args)
      return nil
    end

    def substitute_in_visit(xampl)
      return xampl.substitute_in_visit(self)
    end

    def before_visit(xampl)
      xampl.before_visit(self)
    end

    def after_visit(xampl)
      xampl.after_visit(self)
    end

    def around_visit(xampl)
      return false
    end

    def visit_string(string)
    end

    def start(xampl_in)
      xampl = substitute_in_visit(xampl_in)

      n = @visiting[xampl]
      if n then
        @visiting[xampl] = n + 1
      else
        @visiting[xampl] = 1
      end

      if 1 < @visiting[xampl] then
        return self unless cycle(xampl)
        @cycling = true
        @revisiting = true
      elsif @visited.has_key? xampl then
        return self unless revisit(xampl)
        @revisiting = true
      end

      @visited[xampl] = xampl

      before_visit(xampl)
      if @no_children then
        @no_children = false
        return self
      end

      xampl.visit(self) unless around_visit(xampl) or !xampl.respond_to? "visit"

      return self if @done
      return self if @no_siblings

      if @no_children then
        after_visit(xampl)
        @no_children = false
        return self
      end

      if @short_circuit then
        short_circuit
        @short_circuit = false
      else
        xampl.children.each do | child |
          if child.kind_of?(XamplObject) then
            start(child)
          else
            visit_string(child)
          end

          after_visit(xampl) if @done
          return self if @done

          if @no_siblings then
            @no_siblings = false
            after_visit(xampl)
            return self
          end
        end if xampl.respond_to? "children"
      end

      after_visit(xampl)
      return self

    #rescue  => e
    #  puts "visit failed !!!!! #{ e }"
    #  e.backtrace.each do | trace |
    #    puts "  #{trace}"
    #    break if /actionpack/ =~ trace
    #  end
    #  raise e

    ensure
      n = @visiting[xampl]
      if 1 == n then
        @visiting.delete(xampl)
      else
        @visiting[xampl] = n - 1
      end
      @revisiting = false
      @cycling = false
    end
  end
end

