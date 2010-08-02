
module RedisTest
  attr :invalidated
  class Author
    def init_hook
      # called when initialized by xampl
      @invalidated = false
    end

    def note_invalidate
      # called by xampl to note that this object is invalid
      @invalidated = true
    end

    def invalidated?
      @invalidated
    end
  end
end
