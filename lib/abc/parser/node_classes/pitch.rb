module ABC

  class PitchNode < MusicNode
    def octave
      note_letter.octave + octave_shift.value
    end
    def note
      note_letter.text_value.upcase
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

  # TODO work this out so pseudopitch inherits from pitch or something
  class PseudoPitch
    attr_reader :note
    attr_reader :octave
    attr_reader :accidental
    def initialize(note, accidental=nil, octave=0)
      @note = note
      @octave = octave
    end
    def height
      12 * octave + "C D EF G A B".index(note) + (accidental || 0)
    end
  end

end
