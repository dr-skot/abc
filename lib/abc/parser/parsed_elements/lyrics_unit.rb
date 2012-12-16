module ABC
  class LyricsUnit

    attr_reader :text
    attr_reader :hyphen
    attr_reader :stretch

    def initialize(text, hyphen, stretch)
      @text = text
      @hyphen = hyphen
      @stretch = stretch
    end

    def hyphen?
      hyphen.length > 0
    end

    def note_count
      1 + stretch.length + (hyphen? ? hyphen.length - 1 : 0)
    end

  end
end
