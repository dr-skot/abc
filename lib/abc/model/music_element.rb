module ABC
  class MusicElement < ABCElement

    attr_reader :embellishments
    attr_accessor :chord_symbol

    def initialize(embellishments=nil, type=nil)
      super(type)
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

    def apply_redefinable_symbols(symbols)
      puts self.inspect if embellishments == {}
      embellishments.map! do |em|
        em.shortcut && symbols[em.shortcut] ? symbols[em.shortcut] : em
      end
    end

  end
end
