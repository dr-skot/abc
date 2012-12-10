module ABC

  class Field < ABCNode
    def value
      if content.respond_to? :value
        content.value
      elsif content.respond_to? :text_value
        content.text_value
      else
        content
      end
    end
  end

end
