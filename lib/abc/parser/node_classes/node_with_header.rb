module ABC

  class NodeWithHeader < ABCNode
    attr_accessor :master_node
    def header
      child(Header)
    end
    def info(label)
      fields = header.children(InfoField).select { |f| f.label == label } if header
      if fields && fields.count > 0
        fields.last.value
      else
        master_node.info(label) if master_node
      end
    end

    def field_value(label)
      return nil unless header
      if label
        values = header.values(label)
        if values.count == 0 
          master_node.field_value(label) if master_node
        elsif values.count == 1
          values[0]
        else
          values
        end
      end
    end

    def instructions
      if !@instructions
        @instructions = {}
        if header
          fields = header.fields(/I/)
          fields.each { |f| @instructions[f.name] = f.value }
        end
      end
      @instructions
    end
    
    def method_missing(meth, *args, &block)
      #puts "METHOD MISSING: #{meth}" unless STRING_FIELDS[meth]
      field_value(STRING_FIELDS[meth])
    end

    def meter
      if !@meter && header && (field = header.field(/M/))
        @meter = field.value
      end
      @meter ||= Meter.new :free
    end
  end
  
end
