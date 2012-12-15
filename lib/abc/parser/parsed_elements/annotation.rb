module ABC
  class Annotation < SymbolUnit
    
    attr_reader :placement
    attr_reader :text

    def initialize(placement, text)
      super()
      @placement = placement
      @text = text
    end

  end
end
