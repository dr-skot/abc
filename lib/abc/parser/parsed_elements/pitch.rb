module ABC

  class Pitch
    attr_reader :note
    attr_reader :accidental
    attr_accessor :clef

    def initialize(note, opts = {})
      @note = note.upcase
      @octave = opts[:octave] || 0
      @accidental = opts[:accidental]
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
      12 * octave + "C D EF G A B".index(note) + (accidental || sig[note] || 0) + transposition
    end

    def transposition
      clef ? clef.transpose : 0
    end

    def octave
      @octave + (clef ? clef.octave_shift : 0)
    end
  end

end
