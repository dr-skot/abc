module ABC
  class InstructionField < Field
    attr_accessor :name
    
    def initialize(identifier, name, content)
      super(identifier, content, :instruction)
      @name = name
    end

    def inclusion
      if name == "abc-include"
        @inclusion = IO.read(value).sub(/\s+$/, '') # remove trailing whitespace
      end
    end

  end
end
