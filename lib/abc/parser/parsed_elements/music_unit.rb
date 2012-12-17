require 'abc/parser/parsed_elements/music_element'

module ABC

  class MusicUnit < MusicElement
    attr_accessor :unit_note_length
    attr_accessor :broken_rhythm
    attr_accessor :broken_rhythm_marker
    attr_accessor :chord_length
    attr_accessor :tuplet_ratio
    attr_accessor :tuplet_marker
    attr_accessor :beam
    attr_accessor :lyrics
    attr_accessor :lyric

    def initialize(length, embellishments=nil)
      super(embellishments)
      @specified_length = length
      @lyrics = []
    end

    def lyric
      @lyrics.first
    end

    def specified_length
      @specified_length || 1
    end

    def unit_note_length
      @unit_note_length || 1
    end

    def broken_rhythm
      @broken_rhythm || 1
    end

    def chord_length
      @chord_length || 1
    end

    def tuplet_ratio
      @tuplet_ratio || 1
    end

    def note_length
      specified_length * unit_note_length * broken_rhythm * chord_length * tuplet_ratio
    end
    alias_method :length, :note_length

  end

end
