module ABC
  class Length

    attr_accessor :measure
    attr_accessor :unit

    def initialize(measure, unit)
      @measure = measure
      @unit = unit
    end

  end
end
