module ABC
  class SymbolLine < MusicElement

    attr_reader :symbols

    def initialize(symbols)
      super(:symbol_line)
      @symbols = symbols
    end
      
  end
end
