module ABC
  class TuneNode < ValueNode 
    attr_accessor :file_macros

    def file_macros
      @file_macros ||= {}
    end

    def macros
      @macros ||= next_descendants(MacroFieldNode).inject(file_macros.dup) do |result, m|
        result.merge!(m.target => m) # use hash so later definitions overwrite prior ones
      end
    end

    # TODO get rid of macrofields once used?
    def with_macros
      if (body = child(TuneBodyNode))
        macros.each_value do |m|
          body.with_macros = m.process_text(body.text_value_with_macros)
        end
      end
      nil # with_macros triggers rewrite of tune body but no change on tune node itself
    end

  end

end
