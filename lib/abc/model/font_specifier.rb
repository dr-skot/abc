module ABC
  class FontSpecifier

    attr_accessor :name
    attr_accessor :size

    def initialize(name, size=nil)
      self.name = name
      self.size = size
    end

  end
end
