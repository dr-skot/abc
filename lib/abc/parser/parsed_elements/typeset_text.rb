require "abc/parser/parsed_elements/field"

module ABC

  class TypesetTextLine
    attr_reader :attr
    attr_reader :text
    def initialize(attr, text)
      @attr = attr
      @text = text
    end
  end


  class TypesetText < Field
    attr_reader :lines
    def initialize(lines)
      super('%', lines, :typeset_text)
      @lines = lines
    end
  end

end
