module ABC
  class Header
    
    attr_accessor :master_header
    
    def initialize(fields=nil, master_header=nil)
      @fields = fields || []
      @master_header = master_header
    end

    def fields(*args)
      master_fields = master_header ? master_header.fields(*args) : []
      master_fields.concat(local_fields(*args))
    end

    def fields_replace_master(*args)
      if !master_header
        local_fields(*args)
      else
        args.inject([]) do |result, arg|
          f = local_fields(arg)
          f = master_header.fields(arg) if f == []
          result.concat(f)
        end
      end
    end

    # args can be all type symbols or identifier characters
    def local_fields(*args)
      if args.length == 0
        @fields
      elsif args[0].is_a?(Symbol)
        @fields.select { |f| args.include?(f.type) }
      else
        @fields.select { |f| args.include?(f.identifier) }
      end
    end

    def field(*args)
      list = fields(*args)
      list.count == 0 ? nil : list.count == 1 ? list[0] : list
    end

    def field_replace_master(*args)
      list = fields_replace_master(*args)
      list.count == 0 ? nil : list.count == 1 ? list[0] : list
    end

    #returns the last header field whose label matches
    def last_field(*args)
      fields(*args)[-1]
    end

    # returns the values for all headers whose labels match regex
    def values(*args)
      fields(*args).map { |f| f.value }
    end

    def values_replace_master(*args)
      fields_replace_master(*args).map { |f| f.value }
    end

    def value(*args)
      list = values(*args)
      list.count == 0 ? nil : list.count == 1 ? list[0] : list
    end

    def last_value(*args)
      values(*args)[-1]
    end

    def value_replace_master(*args)
      list = values_replace_master(*args)
      list.count == 0 ? nil : list.count == 1 ? list[0] : list
    end

    def christen(node)
      adjust_parser(node.parser)
    end

    def adjust_parser(parser)
      if (fh = parser.globals[:file_header]) && fh != self
        self.master_header = fh
      end
      field = fields(:instruction).select { |f| f.name == "linebreak" }.last
      field.adjust_parser(parser) if field
    end

  end
end
