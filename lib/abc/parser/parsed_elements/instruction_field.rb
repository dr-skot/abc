module ABC
  class InstructionField < Field
    attr_accessor :name
    
    def initialize(identifier, name, value)
      super(identifier, value, :instruction)
      @name = name
    end
      
    def inclusion
      # sub() here trims trailing whitespace
      @inclusion ||= IO.read(value).sub(/\s+$/, '') if name == "abc-include"
    end
    
    def christen(node)
      if name == 'linebreak'
        dollar, bang = value.include?('$'), value.include?('!')        
        if dollar && bang
          rule = :score_linebreak_both
        elsif dollar
          rule = :score_linebreak_dollar
        elsif bang
          rule = :score_linebreak_bang
        else
          rule = :score_linebreak_none
        end
        node.parser.alias_rule(:score_linebreak, rule)
        if bang
          node.parser.alias_rule(:decoration_delimiter, :decoration_delimiter_plus)
        end
      end
    end
    
  end
end
