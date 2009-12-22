require 'set'

module Xampl

  class Iterator
    attr_accessor :on_seen, :on_cycle, :exhausted, :alive

    def Iterator.create(xampl, options={})
      iterator = Iterator.new(options)
      fib = Fiber.new do
        iterator.consider(xampl)
        iterator.alive = false
        iterator.set_fiber(nil)
      end
      iterator.set_fiber(fib)
      iterator
    end

    def initialize(options)
      case options[:cycle]
        when :stop, :error, :ignore, :notify, :notify_then_stop
          @on_cycle = options[:cycle]
        else
          @on_cycle = :notify_then_stop
      end

      case options[:seen]
        when :stop, :error, :ignore, :notify, :notify_then_stop
          @on_seen = options[:seen]
        else
          @on_seen = :notify_then_stop
      end

      @exhausted = false
      @visiting = Hash.new 0
      @visited = Set.new
      @alive = true
    end

    def set_fiber(fib)
      @fib = fib
    end

    def next(control={})
      return nil, { :done => true } unless alive
      @fib.resume(control)
    end

    def no_children
      return nil, { :done => true } unless alive
      @fib.resume(:no_children => true)
    end

    def stop
      return nil, { :done => true } unless alive
      @fib.resume(:stop => true)
    end

    def ignore
      return nil, { :done => true } unless alive
      @fib.resume(:ignore => true)
    end

    def terminate
      @alive = false
      @fib = nil
      return nil, { :done => true }
    end

    def consider(xampl)
      stop_after_reporting = false
      notices={}

      cycle = (1 < (@visiting[xampl] += 1))
      if cycle then
        case on_cycle
          when :stop
            return
          when :ignore
          when :notify, :notify_then_stop
            stop_after_reporting = true
            notices[:cycling] = true
          when :error
            throw "cycle on :#{ xampl }"
        end
      else
        if @visited.member?(xampl) then
          case on_seen
            when :stop
              return
            when :ignore
            when :notify, :notify_then_stop
              stop_after_reporting = true
              notices[:seen] = true
            when :error
              throw "aleady seen :#{ xampl }"
          end
        end
      end

      @visited << xampl

      notices[:opening] = true
      notices[:closing] = false

      control = (Fiber.yield(xampl, notices) || {})

      notify_on_close = control[:notify_on_close]

      if !control[:continue] && !control[:ignore] && (control[:stop] || control[:no_children] || stop_after_reporting)
        Fiber.yield(xampl, { opening: false, closing: true }) if notify_on_close
        return
      end

      xampl.children.each do | child |
        consider(child)
      end

      Fiber.yield(xampl, { opening: false, closing: true }) if notify_on_close
    end
  end
end

