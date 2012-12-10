module ABC

  class InstructionField < Field
    def christen
      include_file(value) if name == 'abc-include'
    end
    def include_file(filename)
      parser.input_changed = true
      @inclusion = IO.read(filename).sub(/\s+$/, '') # remove trailing whitespace
    end
  end

end
