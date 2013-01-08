module ABC

  class Part
    attr_accessor :id
    attr_accessor :elements

    def initialize(id=nil)
      @id = id
      @elements = []
    end

    def items
      @items ||= elements.select { |element| element.is_a?(MusicElement) }
    end

    def notes
      @notes ||= elements.select { |element| element.is_a?(MusicUnit) }
    end

  end
end
