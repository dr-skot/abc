require 'abc/parser/parsed_elements/music_element'

module ABC
  class BarLine < MusicElement
    attr_reader :type
    attr_reader :repeat_before
    attr_reader :repeat_after
    attr_accessor :dotted
    alias_method :dotted?, :dotted
    def initialize(type, repeat_before=nil, repeat_after=nil, options={})
      super(options)
      @type = type
      @repeat_before = repeat_before
      @repeat_after = repeat_after
    end
  end
end
