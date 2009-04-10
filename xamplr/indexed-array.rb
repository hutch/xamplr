class IndexedArray
  include Enumerable

  def initialize(parent=nil)
    @map = {}
    @store = []
    @parent = nil
  end

  def [](index)
    if String === index or Symbol === index then
      pos = @map[index]
      if pos then
        return @store[pos]
      else
        return nil
      end
    else
      return @store[index]
    end
  end

  alias slice []

  def []=(index, value)
    if String === index or Symbol === index then
      pos = @map[index]
      unless pos then
        pos = @store.size
        @map[index] = pos
      end
      return @store[pos] = value
    else
      raise XamplException.new(:non_string_or_symbol_key)
    end
  end

  def clear
    @map = {}
    @store = []
  end

  def keys
    return @map.keys
  end

  def delete(index)
    if String === index or Symbol === index then
      pos = @map.delete(index)
      if pos then
        @map.each{ | k, v| @map[k] = (v - 1) if pos < v }
        return @store.delete_at(pos)
      end
    else
      key = @map.index(index)
      pos = @map.delete(key) if key
      if pos then
        @map.each{ | k, v | @map[k] = (v - 1) if pos < v }
        return @store.delete_at(pos)
      end
    end
    return nil
  end

  alias delete_at delete

  def size
    @store.size
  end

  alias length size

  def first
    @store.first
  end

  def last
    @store.last
  end

  def each
    @store.each{ | obj | yield(obj) }
  end

  def each_index
    @store.each_index{ | i | yield(i) }
  end

  def each_key_value
    @map.each{ | k, v | yield(k, @store[v]) }
  end

  def sort
    @store.sort{ | a, b | yield(a, b) }
  end

  def sort!
    arr = []
    @map.each{ | index, pos |
      arr << [index, @store[pos]]
    }
    arr.sort!{ | a, b |
      yield(a[1], b[1])
    }
    @map = {}
    @store = []
    arr.each { | pair |
      @map[pair[0]] = @store.size
      @store << pair[1]
    }
  end
end

