module ABC
  class HeaderOld < ABCNode
    alias_method :node_values, :values
    # returns all header fields whose labels match regex
    def fields(regex=nil)
      if regex
        node_values(Field).select { |f| f.identifier =~ regex }
      else
        node_values(Field)
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
