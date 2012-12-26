module ABC
  class MacroFieldNode < ABCNode

    def process_text(s)
      s.gsub(target, value)
    end

  end
end
