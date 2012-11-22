module ABC

  class Pitch
    attr_reader :note
    attr_reader :octave
    attr_reader :accidental
    def initialize(note, opts = {})
      @note = note.upcase
      @octave = opts[:octave] || 0
      @accidental = opts[:accidental] || 0
    end
    def signature
      @signature ||= {}
    end
    # duplicates the signature if the note's accidental changes it
    def signature=(sig)
      if accidental && sig[note] != accidental
        @signature = sig.dup
        @signature[note] = accidental
      else
        @signature = sig
      end
      @signature
    end

    # half steps above C
    def height_in_octave(sig=signature)
      height(sig) % 12
    end
    # half steps above middle C
    def height(sig=signature)
      12 * octave + "C D EF G A B".index(note) + (accidental || sig[note] || 0)
    end
  end

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
      @line = opts[:line] || LINES[name.to_sym]
      @octave_shift = opts[:octave] || 0
      @middle_pitch = opts[:middle] || MIDDLE_PITCHES[name.to_sym]
      @transpose = opts[:transpose] || 0
      @stafflines = opts[:stafflines] || 5
    end

    DEFAULT = Clef.new

  end

end
