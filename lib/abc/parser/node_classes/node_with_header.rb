module ABC

  class NodeWithHeader < ABCNode
    attr_accessor :master_node
    def header
      @header ||= Header.new((n = child(HeaderNode)) ? n.values(Field) : [])
    end

    def master_node=(node)
      header.master_header = node.header
    end
    
    def area
      header.value_replace_master(:area)
    end

    def book
      header.value_replace_master(:book)
    end

    def composer
      header.value_replace_master(:composer)
    end

    def discography
      header.value_replace_master(:discography)
    end
    alias_method :disc, :discography

    def file_url
      header.value_replace_master(:file_url)
    end
    alias_method :url, :file_url

    def group
      header.value_replace_master(:group)
    end

    def history
      header.value_replace_master(:history)
    end

    def meter
      @meter ||= header.last_value(:meter) || Meter.new(:free)
    end

    def notations
      header.value_replace_master(:notations)
    end

    def origin
      header.value_replace_master(:origin)
    end

    def rhythm
      header.value_replace_master(:rhythm)
    end

    def source
      header.value_replace_master(:source)
    end

    def title
      header.value_replace_master(:title)
    end

    def transcription
      header.value_replace_master(:transcription)
    end

    def instructions
      @instructions ||= header.fields(:instruction).inject({}) do |result, field|
        result.merge(field.name => field.value)
      end
    end



=begin
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

    # TODO get rid of this, respond only to the explicit methods
    def method_missing(meth, *args, &block)
      # "METHOD MISSING: #{meth}" unless STRING_FIELDS[meth]
      field_value(STRING_FIELDS[meth])
    end

=end

  end  
end
