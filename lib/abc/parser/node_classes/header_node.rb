module ABC
  class HeaderNode < ValueNode
    def value
      @value ||= Header.new(values(Field), parser.globals[:file_header])
    end

  end
end
