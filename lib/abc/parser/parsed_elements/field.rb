module ABC

  # note: symbol lines (s:) and lyric lines (w:) not treated as regular fields
  FIELD_TYPES = {
    'A' => :area,
    'B' => :book,
    'C' => :composer,
    'D' => :discography,
    'F' => :file_url,
    'G' => :group,
    'H' => :history,
    'I' => :instruction,
    'K' => :key,
    'L' => :unit_note_length,
    'M' => :meter,
    'N' => :notations,
    'O' => :origin,
    'P' => :part_sequence,
    'Q' => :tempo,
    'R' => :rhythm,
    'S' => :source,
    'T' => :title,
    'U' => :user_defined,
    'V' => :voice,
    'W' => :unaligned_lyrics,
    'X' => :refnum,
    'Z' => :transcription,
  }

  class Field < MusicElement

    attr_reader :identifier
    attr_reader :value

    def initialize(identifier, content_value, type=nil)
      super()
      @identifier = identifier
      @value = content_value
      @type = type
    end

    def type
      @type || FIELD_TYPES[identifier]
    end
  end
end
