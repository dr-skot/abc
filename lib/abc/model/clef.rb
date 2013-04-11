require 'abc/model/pitch'

module ABC

  class Clef

    # Indicates which staff line the clef sits on for the basic clefs.
    LINES = {
      :treble => 2,
      :alto => 3,
      :tenor => 4,
      :bass => 4,
    } # :nodoc:

    # Indicates the pitch on the middle staff line for the basic clefs.
    MIDDLE_PITCHES = {
      :treble => Pitch.new('B'),
      :alto => Pitch.new('C'),
      :tenor => Pitch.new('A', :octave => -1),
      :bass => Pitch.new('D', :octave => -1),
      :none => Pitch.new('B'),
    } # :nodoc:

    # _string_ name of the clef eg 'treble', 'bass'
    attr_reader :name

    # _integer_ staff line on which the clef sits
    attr_reader :line

    # _integer_ number of octaves by which to shift all notes
    attr_reader :octave_shift

    # _Pitch_ pitch on the middle staff line
    attr_reader :middle_pitch

    # _integer_ number of semitones by which to shift all notes
    attr_reader :transpose

    # _integer_ number of lines on the staff
    attr_reader :stafflines

    alias_method :middle, :middle_pitch
    
    # Makes a new Clef, with opts as follows:
    # +:name+:: _string_ name of the clef, should be one of 
    #           'treble', 'alto', 'tenor', 'bass', 'none'; 
    #           default 'treble'
    # +:line+:: _integer_ staff line on which the clef should sit (bottom line is 1); 
    #           default depends on name --
    #           for treble 2, alto 3, tenor 4, bass 4, otherwise 2.
    # +:octave_shift+:: _integer_ number of octaves by which to shift all pitches; default 0 
    # +:middle_pitch+:: _Pitch_ pitch on the middle staff line; 
    #                   default depends on name --
    #                   for treble B; for alto A; for tenor A,; for bass D,; otherwise B
    # +:transpose+:: _integer_ number of semitones by which to shift all pitches; default 0 
    # +:stafflines+:: _integer_ number of lines on the staff; default 5 
    def initialize(opts = {})
      @name = opts[:name] || 'treble'
      @line = opts[:line] || LINES[name.to_sym] || LINES[:treble]
      @octave_shift = opts[:octave] || 0
      @middle_pitch = opts[:middle] || MIDDLE_PITCHES[name.to_sym] || MIDDLE_PITCHES[:treble]
      @transpose = opts[:transpose] || 0
      @stafflines = opts[:stafflines] || 5
    end

    # The clef used when no clef is specified (treble).
    DEFAULT = Clef.new

  end

end
