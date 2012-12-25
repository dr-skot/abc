module ABC
  class FreeText

    attr_reader :text

    def initialize(text)
      @text = TextString.new(text)
    end

  end
end
