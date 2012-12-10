module ABC

  # TODO rename this?
  class NoteOrRest < MusicNode
    attr_accessor :unit_note_length
    attr_accessor :broken_rhythm
    attr_accessor :chord_length
    attr_accessor :beam
    attr_accessor :lyric
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
      note_length_node.value * unit_note_length * broken_rhythm * chord_length
    end
  end
  
end
