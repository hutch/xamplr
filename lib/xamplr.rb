
module Xampl

  require 'rubygems'
  require 'yaml'
  require 'logger'

  require 'xamplr-pp'

  @@logger = Logger.new(STDOUT)
  @@logger.level = Logger::WARN

  def Xampl.log
    return @@logger
  end

  require 'xamplr/xampl-module'
  require 'xamplr/xampl-object-internals'
  require 'xamplr/xampl-object'
  require 'xamplr/xampl-persisted-object'

  require 'xamplr/exceptions'
  require 'xamplr/xml-text'
  require 'xamplr/notifications'
  require 'xamplr/mixins'

  require 'xamplr/from-xml'
  require 'xamplr/to-xml'
  require 'xamplr/to-ruby'

  require 'xamplr/visitor'
  require 'xamplr/persist-to-xml'
  require 'xamplr/visitors'

end


