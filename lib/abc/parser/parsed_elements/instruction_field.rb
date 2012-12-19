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
        if value.include?('$') && value.include?('!')
          rule = :tune_linebreak_both
        elsif value.include? '$'
          rule = :tune_linebreak_dollar
        elsif value.include? '!'
          rule = :tune_linebreak_bang
        else
          rule = :tune_linebreak_none
        end
      end
      node.parser.alias_rule(:tune_hard_linebreak, rule)
    end
    
  end
end
