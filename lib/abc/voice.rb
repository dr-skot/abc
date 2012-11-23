module ABC

  class Voice
    attr_accessor :id
    attr_accessor :name
    attr_accessor :subname
    attr_accessor :stem
    attr_accessor :clef
    attr_accessor :items

    def initialize(id, opts={})
      @id = id
      @name = opts[:name]
      @subname = opts[:subname]
      @stem = opts[:stem] if opts[:stem]
      @items = []
    end

    def notes
      items.select { |item| item.is_a? NoteOrRest }
    end

  end
  
end
