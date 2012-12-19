module ABC
  class TuneLine < Part

    attr_accessor :hard_break
    alias_method :hard_break?, :hard_break

    def initialize(hard_break=false)
      super()
      @hard_break = hard_break
    end
  end

end
