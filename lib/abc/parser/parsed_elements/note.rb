require 'abc/parser/parsed_elements/music_unit'

module ABC
  
  class NoteOrChord < MusicUnit
    attr_accessor :grace_notes
    attr_reader :broken_rhythm_marker
    attr_accessor :tied_left
    attr_accessor :tied_right
    attr_accessor :tied_right_dotted
    attr_accessor :start_slur
    attr_accessor :start_dotted_slur
    attr_accessor :end_slur

    def initialize(length, embellishments=nil, options={})
      super(length, embellishments)
      if options
        @grace_notes = options[:grace_notes]
        @broken_rhythm_marker = options[:broken_rhythm_marker]
      end
      @tied_left, @tied_right, @tied_right_dotted = false, false, false
      @start_slur, @start_dotted_slur, @end_slur = 0, 0, 0
    end
  end
  
  class Note < NoteOrChord

    attr_reader :pitch
    attr_accessor :chord

    def initialize(pitch, length, embellishments=nil, options={})
      super(length, embellishments, options)
      @pitch = pitch
    end

    def chord_length
      chord ? chord.length : 1
    end

  end

  class Chord < NoteOrChord

    attr_reader :notes

    def initialize(notes, length, embellishments=nil, options={})
      super(length, embellishments, options)
      @notes = notes
      notes.each { |note| note.chord = self }
    end
  end

end
