module ABC
  class MusicElement < ABCElement

    attr_reader :decorations
    attr_reader :annotations
    attr_accessor :chord_symbol

    def initialize(options={})
      @decorations = options[:decorations] || []
      @annotations = options[:annotations] || []
      @chord_symbol = options[:chord_symbol]
    end

  end
end
