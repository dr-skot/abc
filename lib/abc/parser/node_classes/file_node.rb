module ABC
  class FileNode < ValueNode
    def macros
      @macros ||= next_descendants(MacroFieldNode).inject({}) do |result, m|
        result.merge!(m.target => m) # use hash so later definitions overwrite prior ones
      end
    end

    def with_macros
      next_descendants(TuneNode).each do |tune_node|
        tune_node.file_macros = macros
      end
      nil # with_macros triggers propagation of macros to tunes but no change on file node itself
    end

  end
end
