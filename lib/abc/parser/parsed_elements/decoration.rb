module ABC
  class Decoration < SymbolUnit

    attr_reader :symbol

    def initialize(symbol, shortcut=nil)
      super(shortcut)
      @symbol = symbol
    end

  end
end
