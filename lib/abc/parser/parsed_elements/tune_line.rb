module ABC
  class TuneLine

    attr_reader :items
    attr_accessor :symbols
    attr_accessor :hard_break
    attr_accessor :symbol_lines
    attr_accessor :lyrics_lines
    def initialize(items=[], hard_break=false)
      @items = items
      @hard_break = hard_break
      @symbol_lines = []
      @lyrics_lines = []
    end
    def hard_break?
      @hard_break
    end
    def notes
      items.select { |item| item.is_a?(NoteOrRest) }
    end
  end

end
