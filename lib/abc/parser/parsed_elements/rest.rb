module ABC
  class MusicUnit
    attr_accessor :unit_note_length
    attr_accessor :broken_rhythm
    attr_accessor :broken_rhythm_marker
    attr_accessor :chord_length
    attr_accessor :beam
    attr_accessor :lyric

    def specified_note_length
      @specified_note_length || 1
    end

    def unit_note_length
      @unit_note_length || 1
    end

    def broken_rhythm
      @broken_rhythm || 1
    end

    def chord_length
      @chord_length || 1
    end

    def note_length
      specified_note_length * unit_note_length * broken_rhythm * chord_length
    end
    alias_method :length, :note_length

  end

  class Rest < MusicUnit

    def initialize(length, options = {})
      @specified_note_length = length
      @invisible = options[:invisible]
    end

    def invisible?
      @invisible
    end

  end

  class MeasureRest < MusicUnit
    attr_reader :measure_count
    attr_accessor :measure_length

    def initialize(measure_count, options = {})
      @measure_count = measure_count
      @invisible = options[:invisible]
    end

    def note_length
      measure_length * measure_count if measure_length
    end

    def invisible?
      @invisible
    end

  end
end
