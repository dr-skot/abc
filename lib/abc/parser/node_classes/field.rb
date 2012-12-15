module ABC

  class Field < ABCNode
    def val
      FField.new(text_value[0], content_value)
    end
    def content_value
      @value ||= content.value ? content.value :
        content.respond_to?(:text_value) ? content.text_value :
        content
    end
    alias_method :value, :content_value
    def type
      respond_to?(:content) ? val.type : ABC::FField::FIELD_TYPES[text_value[0]]
    end
  end

end
