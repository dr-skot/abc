module ABC
  class LyricsUnit

    attr_reader :text
    attr_reader :hyphen
    attr_reader :stretch
    attr_reader :prehyphen

    def initialize(text, hyphen, stretch, prehyphen=nil)
      @text = text
      @hyphen = hyphen
      @stretch = stretch
      @prehyphen = prehyphen
    end

    def hyphen?
      hyphen.length > 0
    end

    def note_count
      1 + stretch.length + (hyphen? ? hyphen.length - 1 : 0)
    end

    def note_skip
      prehyphen ? prehyphen.length : 0
    end

  end
end
