module ABC
  class ChordSymbol < SymbolUnit
    
    attr_reader :text

    def initialize(text, shortcut=nil)
      super(shortcut)
      @text = text
    end

  end
end
