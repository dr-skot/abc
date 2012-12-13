require 'abc/parser/parsed_elements/music_element'

module ABC
  class BarLine < MusicElement
    attr_reader :type
    attr_reader :repeat_before
    attr_reader :repeat_after
    attr_reader :variant_number
    def initialize(type, repeat_before=nil, repeat_after=nil, variant_number=nil)
      @type = type
      @repeat_before = repeat_before
      @repeat_after = repeat_after
      @variant_number = variant_number
    end
  end
end
