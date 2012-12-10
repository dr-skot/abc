module ABC

  class Decoration
    attr_reader :symbol
    def initialize(symbol)
      @symbol = symbol
    end
    def type
      :decoration
    end
  end

end
