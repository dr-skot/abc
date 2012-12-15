module ABC
  class SymbolSkip < SymbolUnit
    attr_reader :type
    def initialize(type)
      super()
      @type = type
    end
  end
end
