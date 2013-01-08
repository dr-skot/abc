module ABC
  class ABCElement
    
    attr_reader :type
    attr_accessor :part
    attr_accessor :voice

    def initialize(type)
      @type = type
    end

    CODE_LINEBREAK = ABCElement.new(:code_linebreak)
    SCORE_LINEBREAK = ABCElement.new(:score_linebreak)

  end
end
