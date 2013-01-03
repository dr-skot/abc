module ABC

  class Measure < Part
    attr_accessor :left_bar
    attr_accessor :right_bar
    attr_accessor :overlays
    attr_accessor :number

    def initialize(options={})
      super(nil)
      @number = options[:number] || 1
      @overlays = []
    end

    def empty?
      elements.empty? && left_bar == nil
    end

    def overlay
      overlays[0]
    end
    
    def overlays?
      overlays.count > 0
    end
    
    def new_overlay
      overlays << (result = Measure.new); result
    end

  end
  
end
