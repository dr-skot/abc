module ABC

  class PartsUnit < ABCNode
    def list
      parts = []
      reset
      while (p = next_part)
        parts << p
      end
      reset
      parts
    end
    def repeat
      if repeat_node && !repeat_node.empty?
        repeat_node.value
      else
        1
      end
    end
  end
  
  class PartSequence < PartsUnit
    def next_part
      @child_index ||= 0
      kids = children(PartsUnit)
      if @child_index < kids.count
        part = kids[@child_index].next_part
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
      children(PartsUnit).each { |kid| kid.reset }
    end
  end
  
  class PartsGroup < PartsUnit
    def next_part
      @repeat_index ||= 0
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
    def next_part
      @index ||= 0
      if @index < repeat
        @index += 1
        part.text_value
      end
    end
    def reset
      @index = 0
    end
  end

end
