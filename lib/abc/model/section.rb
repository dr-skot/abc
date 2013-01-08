module ABC
  class Section

    def initialize(children)
      @children = children
    end

    def children(*args)
      args.count == 0 ? @children : @children.select { |it| it.is_one_of?(*args) }
    end

  end
end
