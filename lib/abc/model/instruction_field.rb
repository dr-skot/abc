module ABC
  class InstructionField < Field
    attr_accessor :directive
    attr_accessor :subdirective
    alias_method :name, :directive
    
    def initialize(identifier, directive, value, options={})
      super(identifier, value, :instruction)
      @directive = directive
      @subdirective = options[:subdirective]
    end
      
    def inclusion
      # sub() here trims trailing whitespace
      @inclusion ||= IO.read(value).sub(/\s+$/, '') if name == "abc-include"
    end
    
    def adjust_parser(parser)
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
        parser.alias_rule(:score_linebreak, rule)
        if bang
          parser.alias_rule(:decoration_delimiter, :decoration_delimiter_plus)
        end
      elsif name == 'decoration'
        rule = value == '+' ? :decoration_delimiter_plus : :decoration_delimiter_bang
        parser.alias_rule(:decoration_delimiter, rule)
      end
    end
    
  end
end
