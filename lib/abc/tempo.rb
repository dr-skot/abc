module ABC

  class Fraction
    attr_accessor :numerator, :denominator
    def initialize(num=1, den=1)
      @numerator = num
      @denominator = den
    end
    def to_f
      1.0 * numerator / denominator
    end
    def to_s
      "#{numerator}/#{denominator}"
    end
    def to_rational
      Rational @numerator, @denominator
    end

    # returns whether this fraction represents a dotted note
    def dotted?
    end
  end

  class NoteType
    attr_reader :type, :dotted
    def initialize(numerator, denominator)
      if denominator & (denominator-1) == 0 # is denominator a power of 2?
        if numerator == 1 && denominator >= 1 && denominator <= 64
          @type = denominator
          @dotted = false
        elsif numerator == 3 && denominator >= 2 && denominator <= 128
          @type = denominator/2
          @dotted = true
        end
      end
    end
  end

  class Tempo
    attr_accessor :unit_length
    attr_accessor :beat_parts
    attr_accessor :bpm
    attr_accessor :label
    
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
