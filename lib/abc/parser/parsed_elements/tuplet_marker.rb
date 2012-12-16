module ABC
  class TupletMarker < MusicElement

    attr_accessor :compound_meter
    alias_method :compound_meter?, :compound_meter

    def initialize(p, q, r)
      super()
      @p, @q, @r = p, q, r
      @q = "  323n2n3n"[@p] unless @q
      @r = @p unless @r
    end
    
    def ratio
      q = @q == 'n' ? (compound_meter? ? 3 : 2) : @q.to_i
      Rational(q, @p)
    end

    def num_notes
      @r
    end

    def number_to_print
      @p
    end

  end
end
