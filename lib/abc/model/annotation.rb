module ABC
  class Annotation < SymbolUnit
    
    attr_reader :placement
    attr_reader :text

    def initialize(placement, text, shortcut=nil)
      super(shortcut)
      @placement = placement
      @text = TextString.new(text)
    end

  end
end
