module ABC
  class MidiSettings
    
    def initialize(fields)
      @fields = fields
    end

    def voices
      @voices ||= @fields.inject({}) do |result, field|
        result.merge!(field.value.voice => field.value) if field.subdirective == 'voice'
      end
    end

    def chordprog
      @chordprog_field ||= @fields.select { |f| f.subdirective == 'chordprog' }.last
      @chordprog_field ? @chordprog_field.value : nil
    end

  end
end
