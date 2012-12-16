require 'abc/parser/parsed_elements/music_unit'

module ABC

  class Rest < MusicUnit
    def initialize(length, options={})
      super(length)
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
      super(nil)
      @measure_count = measure_count
      @invisible = options[:invisible]
    end
    def note_length
      measure_length * measure_count if measure_length
    end
    alias_method :length, :note_length
    def invisible?
      @invisible
    end
  end

end
