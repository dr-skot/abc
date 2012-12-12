module ABC
  
  class NoteOrChord < MusicUnit
    attr_reader :decorations
    attr_reader :annotations
    attr_accessor :chord_symbol
    attr_reader :broken_rhythm_marker

    def initialize(length, options={})
      super(length)
      @decorations = options[:decorations] || []
      @annotations = options[:annotations] || []
      @chord_symbol = options[:chord_symbol]
      @broken_rhythm_marker = options[:broken_rhythm_marker]
    end
  end
  
  class Note < NoteOrChord

    attr_reader :pitch
    attr_accessor :chord

    def initialize(pitch, length, options={})
      super(length, options)
      @pitch = pitch
    end

    def chord_length
      chord ? chord.length : 1
    end

  end

  class Chord < NoteOrChord

    attr_reader :notes

    def initialize(notes, length, options={})
      super(length, options)
      @notes = notes
      notes.each { |note| note.chord = self }
    end
  end

end
