module ABC
  class ABCElement
    
    attr_reader :type
    attr_accessor :part
    attr_accessor :voice

    def initialize(type)
      @type = type
    end

    SOFT_LINEBREAK = ABCElement.new(:soft_linebreak)
    HARD_LINEBREAK = ABCElement.new(:hard_linebreak)
    OVERLAY_DELIMITER = ABCElement.new(:overlay_delimiter)

  end
end
