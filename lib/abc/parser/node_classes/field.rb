module ABC

  class Field < ABCNode
    def val
      FField.new(text_value[0], content_value)
    end
    def content_value
      if content.respond_to? :value
        content.value
      elsif content.respond_to? :text_value
        content.text_value
      else
        content
      end
    end
    alias_method :value, :content_value
  end

end
