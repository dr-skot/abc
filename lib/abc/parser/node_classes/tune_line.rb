module ABC

  class TuneLine
    attr_reader :items
    attr_accessor :symbols
    attr_accessor :lyrics
    attr_accessor :hard_break
    def initialize(items=[], hard_break=false)
      @items = items
      @hard_break = hard_break
    end
    def hard_break?
      @hard_break
    end
    def notes
      items.select { |item| item.is_a?(NoteOrRest) }
    end
  end

end
