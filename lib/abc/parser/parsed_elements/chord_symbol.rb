module ABC
  class ChordSymbol < SymbolUnit
    
    attr_reader :text

    def initialize(text)
      super()
      @text = text
    end

  end
end
