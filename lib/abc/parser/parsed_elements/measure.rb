module ABC

  class Measure
    attr_accessor :left_bar
    attr_accessor :right_bar
    attr_accessor :items
    attr_accessor :overlays

    def initialize
      @items = []
      @overlays = []
    end

    def notes
      items.select { |item| item.is_a? MusicUnit }
    end

    def overlays?
      overlays.count > 0
    end

  end
  
end
