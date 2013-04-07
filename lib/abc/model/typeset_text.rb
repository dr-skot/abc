require "abc/model/field"

module ABC

  class TypesetTextLine
    attr_reader :attr
    attr_reader :text
    def initialize(attr, text)
      @attr = attr
      @text = TextString.new(text)
    end
    def alignment
      # TODO refine this
      attr == 'center' ? :center : :left
    end
  end

  class TypesetText < Field
    attr_reader :lines
    def initialize(lines)
      super('%', lines, :typeset_text)
      @lines = lines
    end
    def text
      TextString.new @lines.map { |line| line.text }.join("\n");
    end
  end

end
