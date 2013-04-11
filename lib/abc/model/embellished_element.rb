module ABC
  
  # Base class for musical elements that can have embellishments.
  #
  # Subclasses are MusicUnit, BarLine, Spacer.
  # 
  # Embellishments are annotations, decorations, and/or chord symbols.
  class EmbellishedElement < MusicItem

    # <em>array of SymbolUnit</em> 
    # Any annotations, decorations, or chord symbols attached to this element.
    attr_reader :embellishments

    # Creates a new music element with optional embellishments.
    def initialize(embellishments=nil, type=nil)
      super(type)
      @embellishments = embellishments || []
    end

    # <em>array of Decoration</em> 
    # Returns all the embellishements that are Decoration objects.
    def decorations
      embellishments.select { |e| e.is_a?(Decoration) }
    end

    # <em>array of Annotation</em> 
    # Returns all the embellishments that are Annotation objects.
    def annotations
      embellishments.select { |e| e.is_a?(Annotation) }
    end

    # _ChordSymbol_ Returns the embellishment that is a ChordSymbol, if any.
    # There should not be more than one chord symbol, but if there is
    # this method will only return the last one.
    def chord_symbol
      @chord_symbol ||= embellishments.select { |e| e.is_a?(ChordSymbol) }[-1]
    end

  end
end
