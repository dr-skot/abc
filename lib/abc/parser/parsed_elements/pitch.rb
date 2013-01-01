module ABC

  class Pitch
    attr_reader :note
    attr_reader :accidental
    attr_accessor :key_signature
    attr_accessor :local_accidentals
    attr_accessor :clef

    def initialize(note, opts = {})
      @note = note.upcase
      @octave = opts[:octave] || 0
      @accidental = opts[:accidental]
      @local_accidentals = {}
    end

    def key_signature
      @key_signature ||= {}
    end

    # half steps above C
    def height_in_octave
      height % 12
    end

    # half steps above middle C
    def height
      12 * octave + "C D EF G A B".index(note) + adjusted_accidental + transposition
    end

    def adjusted_accidental
      accidental || local_accidental || key_signature[note] || 0
    end

    def local_accidental
      local_accidentals[note] || local_accidentals[[note, octave]]
    end

    def transposition
      clef ? clef.transpose : 0
    end

    def octave
      @octave + (clef ? clef.octave_shift : 0)
    end

    def set_accidentals(signature, locals)
      self.key_signature = signature
      self.local_accidentals = locals
    end
  end

end
