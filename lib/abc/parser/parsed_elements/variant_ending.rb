module ABC
  class VariantEnding < MusicElement
    attr_reader :range_list
    def initialize(range_list)
      @range_list = range_list
    end
  end
end
