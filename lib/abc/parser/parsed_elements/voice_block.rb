module ABC
  class VoiceBlock

    attr_reader :list
    attr_reader :type
    attr_accessor :continue_bar_lines
    attr_accessor :start_brace
    attr_accessor :end_brace
    attr_accessor :start_bracket
    attr_accessor :end_bracket

    alias_method :continue_bar_lines?, :continue_bar_lines

    def initialize(list, options={:type => :staff})
      @list = list
      @type = options[:type]
      @continue_bar_lines = options[:continue_bar_lines] ? true : false
      @start_brace = 0
      @end_brace = 0
      if type == :braced
        staves.first.start_brace += 1
        staves.last.end_brace += 1
      end
      @start_bracket = 0
      @end_bracket = 0
      if type == :bracketed
        staves.first.start_bracket += 1
        staves.last.end_bracket += 1
      end
    end

    def staves
      @staves ||= (type == :staff) ? [self] : list.map { |el| el.staves }.flatten
    end

    def voices
      staves.map { |s| s.list }.flatten
    end

  end
end