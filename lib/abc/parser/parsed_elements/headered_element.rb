module ABC

  class HeaderedElement

    def initialize(raw_items)
      @raw_items = raw_items
    end

    def values(*args)
      args.count == 0 ? @raw_items : @raw_items.select { |it| it.is_one_of?(*args) }
    end

    attr_accessor :master_node
    def header
      @header ||= values(Header).last || Header.new
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

  end
end
