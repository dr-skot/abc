module ABC
  class VariantEnding < MusicItem

    attr_reader :range_list

    def initialize(range_list)
      super()
      @range_list = range_list
    end

  end
end
