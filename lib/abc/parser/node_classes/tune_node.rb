module ABC
  class TuneNode < ValueNode 

    def macros
      @macros ||= children(MacroFieldNode).inject({}) do |result, m|
        result.merge!(m.target => m) # use hash so later definitions overwrite prior ones
      end
    end

    # TODO get rid of macrofields once used?
    def with_macros
      if (body = child(TuneBodyNode))
        macros.each_value do |m|
          body.with_macros == m.change_text(body.with_macros)
        end
      end
    end

  end

end
