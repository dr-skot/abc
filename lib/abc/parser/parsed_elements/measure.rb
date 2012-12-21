module ABC

  class Measure < Part
    attr_accessor :left_bar
    attr_accessor :right_bar
    attr_accessor :overlays

    def initialize
      super(nil)
      @overlays = []
    end

    def overlays?
      overlays.count > 0
    end
    
    def empty?
      elements.empty? && left_bar == nil
    end

    def new_overlay
      overlays << (result = Measure.new); result
    end

  end
  
end
