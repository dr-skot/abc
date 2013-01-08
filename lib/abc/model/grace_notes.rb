module ABC
  class GraceNotes
    attr_reader :type
    attr_reader :notes
    def initialize(type, notes)
      @type = type
      @notes = notes
    end
  end
end
