module ABC
  class SymbolLine < ABCElement

    attr_reader :symbols

    def initialize(symbols)
      super(:symbol_line)
      @symbols = symbols
    end
      
  end
end
