require 'abc/model/music_element'

module ABC
  class BarLine < EmbellishedElement
    attr_reader :type
    attr_reader :repeat_before
    attr_reader :repeat_after
    attr_accessor :dotted
    alias_method :dotted?, :dotted
    # TODO options should be embellishments
    def initialize(type, repeat_before=nil, repeat_after=nil, options={})
      super(options)
      @type = type
      @repeat_before = repeat_before
      @repeat_after = repeat_after
    end
  end
end
