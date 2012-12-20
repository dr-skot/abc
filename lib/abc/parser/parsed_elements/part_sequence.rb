module ABC

  class PartsUnit

    attr_reader :repeat

    def initialize(repeat=1)
      @repeat = repeat
    end

    def list
      reset
      parts = []
      while (p = next_part); parts << p; end
      reset
      parts
    end

  end

  class PartSequence < PartsUnit

    attr_reader :children

    def initialize(children)
      super()
      @children = children
      @child_index = 0
    end

    def next_part
      if @child_index < children.count
        part = children[@child_index].next_part
        if part
          part
        else
          @child_index += 1
          next_part
        end
      end
    end

    def reset
      @child_index = 0
      children.each { |kid| kid.reset }
    end

  end


  class PartsGroup < PartsUnit

    attr_reader :parts

    def initialize(parts, repeat)
      super(repeat)
      @parts = parts
      @repeat_index = 0
    end

    def next_part
      if @repeat_index < repeat
        part = parts.next_part
        if part
          part
        else
          @repeat_index += 1
          parts.reset
          next_part
        end
      end
    end

    def reset
      @repeat_index = 0
      parts.reset
    end

  end

  class PartsAtom < PartsUnit

    attr_reader :name

    def initialize(name, repeat)
      super(repeat)
      @name = name
      @repeat_index = 0
    end

    def next_part
      if @repeat_index < repeat
        @repeat_index += 1
        name
      end
    end

    def reset
      @repeat_index = 0
    end

  end



end
