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
        p.assign_free_text
        p.propagate_tunebook_header
        p.divvy_voices
        p.divvy_parts
        p.apply_note_lengths
        p.apply_chord_lengths
        p.apply_broken_rhythms
        p.apply_meter
        p.apply_key_signatures
        p.apply_symbol_lines
        p.apply_lyrics
        p.collect_measures
      end
      p
    end

    def parse_fragment(input)
      p = @parser.parse(input, :root => :abc_fragment)
      if p
        p.divvy_voices
        p.divvy_parts
        p.apply_note_lengths
        p.apply_chord_lengths
        p.apply_broken_rhythms
        p.apply_meter
        p.apply_key_signatures
        p.apply_symbol_lines
        p.apply_lyrics
        p.collect_measures
      end
      p
    end

    def base_parser
      @parser
    end
  end

end
