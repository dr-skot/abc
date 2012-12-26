module ABC
  class MacroFieldNode < ABCNode

    def process_text(s)
      s.gsub(target, replacement)
    end

  end
end
