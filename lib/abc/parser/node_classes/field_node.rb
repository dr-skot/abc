module ABC

  class FieldNode < ValueNode
    def value
      Field.new(text_value[0], content_value, type)
    end
    def content_value
      @value ||= content.value ? content.value : content.text_value
    end
    def type
      nil
    end

  end

end
