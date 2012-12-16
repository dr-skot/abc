module ABC

  # TODO: not complete
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
    'X' => :refnum,
    'Z' => :transcription,
  }

  class Field

    attr_reader :identifier
    attr_reader :value

    def initialize(identifier, content_value, type=nil)
      @identifier = identifier
      @value = content_value
      @type = type
    end

    def type
      @type || FIELD_TYPES[identifier]
    end
  end
end
