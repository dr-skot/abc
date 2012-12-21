module ABC
  class OverlayMarker < ABCElement
    
    attr_reader :num_measures

    def initialize(num_measures)
      super(:overlay_marker)
      @num_measures = num_measures
    end

  end
end
