require 'polyglot'
require 'treetop'

module ABC

  class Parser
    def initialize
      @parser = ABCParser.new
    end

    def parse(input)
      p = @parser.parse input
      if p
        p.divvy_voices
        p.apply_note_lengths
        p.apply_chord_lengths
        p.apply_broken_rhythms
        p.apply_meter
        p.apply_key_signatures
        p.apply_lyrics
      end
      p
    end

    def base_parser
      @parser
    end
  end

end
