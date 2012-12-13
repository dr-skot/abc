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
    'P' => :part,
    'Q' => :tempo,
    'R' => :rhythm,
    'S' => :source,
    'T' => :title,
    'V' => :voice,
    'Z' => :transcription,
  }

  class FField



    attr_reader :identifier
    attr_reader :value

    def initialize(identifier, content_value)
      @identifier = identifier
      @value = content_value
    end

    def type
      FIELD_TYPES[identifier]
    end
  end
end
