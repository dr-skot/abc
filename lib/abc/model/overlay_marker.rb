module ABC
  class OverlayMarker < MusicElement
    
    attr_reader :num_measures

    def initialize(num_measures)
      super(:overlay_marker)
      @num_measures = num_measures
    end

  end
end
