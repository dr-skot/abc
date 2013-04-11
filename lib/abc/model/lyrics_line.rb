module ABC
  class LyricsLine < MusicElement

    attr_reader :units

    def initialize(units)
      super(:lyrics_line)
      @units = units
    end
      
  end
end
