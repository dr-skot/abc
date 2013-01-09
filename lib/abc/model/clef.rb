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

    # name of the clef eg 'treble', 'bass'; _string_
    attr_reader :name

    # staff line on which the clef sits; _integer_
    attr_reader :line

    # number of octaves by which to shift all notes; _integer_
    attr_reader :octave_shift

    # pitch on the middle staff line; <em>ABC::Pitch</em>
    attr_reader :middle_pitch

    # number of semitones by which to shift all notes; _integer_
    attr_reader :transpose

    # number of lines on the staff; _integer_
    attr_reader :stafflines

    alias_method :middle, :middle_pitch
    
    # Makes a new Clef, with opts as follows:
    # +:name+:: name of the clef, should be one of 'treble', 'alto', 'tenor', 'bass', 'none'; 
    #           default 'treble'
    # +:line+:: staff line on which the clef should sit (bottom line is 1); 
    #           default depends on name --
    #           for treble 2, alto 3, tenor 4, bass 4, otherwise 2.
    # +:octave_shift+:: number of octaves by which to shift all pitches; default 0 
    # +:middle_pitch+:: pitch on the middle staff line (a Pitch object); default depends on name --
    #                   for treble B; for alto A; for tenor A,; for bass D,; otherwise B
    # +:transpose+:: number of semitones by which to shift all pitches; default 0 
    # +:transpose+:: number of lines on the staff; default 5 
    def initialize(opts = {})
      @name = opts[:name] || 'treble'
      @line = opts[:line] || LINES[name.to_sym] || LINES[:treble]
      @octave_shift = opts[:octave] || 0
      @middle_pitch = opts[:middle] || MIDDLE_PITCHES[name.to_sym] || MIDDLE_PITCHES[:treble]
      @transpose = opts[:transpose] || 0
      @stafflines = opts[:stafflines] || 5
    end

    # The clef to use when no clef is specified.
    DEFAULT = Clef.new

  end

end
