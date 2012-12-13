module ABC

  class Clef

    LINES = {
      :treble => 2,
      :alto => 3,
      :tenor => 4,
      :bass => 4,
    }

    MIDDLE_PITCHES = {
      :treble => Pitch.new('B'),
      :alto => Pitch.new('C'),
      :tenor => Pitch.new('A', :octave => -1),
      :bass => Pitch.new('D', :octave => -1),
      :none => Pitch.new('B'),
    }

    attr_reader :name
    attr_reader :line
    attr_reader :octave_shift
    attr_reader :middle_pitch
    attr_reader :transpose
    attr_reader :stafflines

    alias_method :middle, :middle_pitch
    
    def initialize(opts = {})
      @name = opts[:name] || 'treble'
      @line = opts[:line] || LINES[name.to_sym] || LINES[:treble]
      @octave_shift = opts[:octave] || 0
      @middle_pitch = opts[:middle] || MIDDLE_PITCHES[name.to_sym] || MIDDLE_PITCHES[:treble]
      @transpose = opts[:transpose] || 0
      @stafflines = opts[:stafflines] || 5
    end

    DEFAULT = Clef.new

  end

end
