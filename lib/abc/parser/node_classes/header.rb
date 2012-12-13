module ABC
  class Header < ABCNode
    # returns all header fields whose labels match regex
    def fields(regex=nil)
      if regex
        children(Field).select { |f| f.text_value[0] =~ regex }
      else
        children(Field)
      end
    end
    #returns the last header field whose label matches
    def field(regex=nil)
      fields(regex)[-1]
    end
    # returns the values for all headers whose labels match regex
    def values(regex)
      fields(regex).map { |f| f.value }
    end
    def value(regex)
      if (f = field(regex))
        f.value
      else
        nil
      end
    end
  end
end
