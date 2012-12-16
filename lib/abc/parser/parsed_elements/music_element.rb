module ABC
  class MusicElement < ABCElement

    attr_reader :embellishments
    attr_accessor :chord_symbol

    def initialize(embellishments)
      @embellishments = embellishments || []
    end
    
    def decorations
      embellishments.select { |e| e.is_a?(Decoration) }
    end

    def annotations
      embellishments.select { |e| e.is_a?(Annotation) }
    end

    def chord_symbol
      @chord_symbol ||= embellishments.select { |e| e.is_a?(ChordSymbol) }[-1]
    end

  end
end
