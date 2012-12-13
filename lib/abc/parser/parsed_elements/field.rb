module ABC
  class FField
    attr_reader :identifier
    attr_reader :value

    def initialize(identifier, content_value)
      @identifier = identifier
      @value = content_value
    end
  end
end
