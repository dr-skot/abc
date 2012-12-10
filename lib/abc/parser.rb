require 'polyglot'
require 'treetop'

module ABC

  class Parser

    def parse(input)
      @parser = ABCParser.new
      p = @parser.parse input          
      if p
        text_value = p.text_value_with_inclusions
        if text_value != input
          parse text_value
        else
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
          p
        end
      end
    end

    def parse_fragment(input)
      @parser = ABCParser.new
      p = @parser.parse(input, :root => :abc_fragment)
      if p
        text_value = p.text_value_with_inclusions
        if text_value != input
          parse_fragment text_value
        else
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
          p
        end
      end
    end

    def base_parser
      @parser
    end
  end

end
