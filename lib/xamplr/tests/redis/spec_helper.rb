$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../../..'))

#require 'weakref'

require 'xamplr'

Xampl.set_default_persister_kind(:in_memory)

require 'xampl-generated-code/all'

require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|

end

module XamplTestRedis

  @@load_time = Time.now.to_i.to_s
  @@scratch_name_count = 0

  def XamplTestRedis.scratch_name(prefix='scratch')
    "#{prefix}-#{ @@load_time }-#{ @@scratch_name_count += 1 }"
  end

  class DroolingIdiotPersistedObject
    include Xampl::XamplPersistedObject

    attr_accessor :pid

    def initialize(pid)
      @pid = pid
    end

    def get_the_index
      @pid
    end

    def persisted?
      true
    end

  end

end
