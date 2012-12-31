module ABC
  class Staff

    def self.list(list, options={})
      list = list.flatten
      if options[:type] == :braced
        list.first.start_brace += 1
        list.last.end_brace += 1
      end
      if options[:type] == :bracketed
        list.first.start_bracket += 1
        list.last.end_bracket += 1
      end
      if options[:invert_bar_continuation]
        list.each { |s| s.continue_bar_lines = !s.continue_bar_lines }
      end
      list
    end

    attr_reader :voices
    attr_reader :floaters
    attr_accessor :continue_bar_lines
    attr_accessor :start_brace
    attr_accessor :end_brace
    attr_accessor :start_bracket
    attr_accessor :end_bracket

    alias_method :continue_bar_lines?, :continue_bar_lines

    def initialize(voices, options={})
      @voices = voices
      @floaters = options[:floaters] || []
      @continue_bar_lines = options[:continue_bar_lines] ? true : false
      @start_brace = 0
      @end_brace = 0
      @start_bracket = 0
      @end_bracket = 0
    end

  end
end
