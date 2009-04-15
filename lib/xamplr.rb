#!/usr/bin/env ruby

module Xampl

  require "yaml"
  require "logger"

  require "xamplr-pp"

  @@logger = Logger.new(STDOUT)
  @@logger.level = Logger::WARN

  def Xampl.log
    return @@logger
  end

  require "xamplr/xampl-object"
  require "xamplr/persistence"
  require "xamplr/notifications"
  require "xamplr/mixins"
  require "xamplr/from-xml"
  require "xamplr/to-xml"
  require "xamplr/to-ruby"
  require "xamplr/visitor"

end


