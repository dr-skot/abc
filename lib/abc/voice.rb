module ABC

  class Voice
    attr_accessor :id
    attr_accessor :name
    attr_accessor :subname
    attr_accessor :stem
    attr_accessor :clef

    def initialize(id)
      @id = id
    end

  end
  
end
