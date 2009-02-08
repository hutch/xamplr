#!/usr/bin/env ruby

module Xampl

  require "yaml"
  require "logger"

  @@logger = Logger.new(STDOUT)
  @@logger.level = Logger::WARN

  def Xampl.log
    return @@logger
  end

  require "xampl-object"
  require "persistence"
  require "notifications"
  require "mixins"
  require "from-xml"
  require "to-xml"
  require "to-ruby"
  require "visitor"

end


