
require "xamplr/persister"


module Xampl

  @@xampl_extends_symbols = false

  def Xampl.xampl_extends_symbols
    @@xampl_extends_symbols
  end

  def Xampl.xampl_extends_symbols=(v)
    @@xampl_extends_symbols = v

    if @@xampl_extends_symbols then
      Symbol.module_eval("include XamplExtensionsToRubyObjects")
    end
  end

  class XamplLiteralRubyObject
    def initialize(thing)
      @thing = thing
    end

    def to_xml(out="")
      out << @thing.to_s
    end
  end

  module XamplExtensionsToRubyObjects
    def to_xml(out="")
      out << self.to_s
    end
  end
end
