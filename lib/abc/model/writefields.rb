module ABC
  class Writefields

    def initialize(chars, add=true)
      ArgumentError.raise unless chars =~ /^[A-Za-z]+$/
      @chars = chars
      @remove = !add
    end

    def apply(orig_chars)
      @chars.each_char.inject(orig_chars) do |chars, c|
        @remove ? chars.delete(c) : chars + (chars.include?(c) ? '' : c)
      end
    end

  end
end
