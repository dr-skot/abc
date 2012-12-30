module ABC
  class HeaderNode < ValueNode
    def value
      @value ||= Header.new(values(Field))
    end

  end
end
