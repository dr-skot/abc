module ABC

  class Tempo
    attr_accessor :unit_length
    attr_accessor :beat_parts
    attr_accessor :bpm
    attr_accessor :label
    
    def initialize(options={})
      @beat_parts = options[:beat_parts]
      @bpm = options[:bpm]
      @label = options[:label]
    end

    def unit_length
      @unit_length || 1
    end

    def note_length(num, den)
      Rational(num, den) * unit_length
    end

    def beat_parts
      @beat_parts || [unit_length]
    end

    def beat_length
      if beat_parts.is_a?(Array)
        beat_parts.reduce(:+)
      else
        beat_parts
      end
    end
    
    def bps
      bpm / 60
    end

    def bpm
      @bpm || 120
    end

    # in seconds
    def note_duration(num, den)
      Rational(num, den) * unit_length / beat_length / bps
    end
    
  end

end
