module ABC
  class Decoration < SymbolUnit

    attr_reader :symbol
    attr_reader :original_text

    def initialize(symbol, original_text=nil)
      super()
      @symbol = symbol
      @original_text = original_text
    end

  end
end
