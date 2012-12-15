
module ABC

  class Parser

    def parse(input, options = {})
      @parser = ABCParser.new
      p = @parser.parse(input, options)
      if p
        if @parser.input_changed?
          parse(p.text_value_with_inclusions, options)
        else
          if p.is_a? Tunebook
            p.assign_free_text
            p.propagate_tunebook_header
          end
          p.divvy_voices
          p.divvy_parts
          p.apply_note_lengths
          p.apply_broken_rhythms
          p.apply_ties_and_slurs
          p.apply_beams
          p.apply_meter
          p.apply_tuplets
          p.apply_key_signatures
          p.apply_clefs
          p.apply_symbol_lines
          p.apply_lyrics
          p.collect_measures
          p
        end
      end
    end

    def parse_fragment(input)
      parse(input, :root => :abc_fragment)
    end

    def base_parser
      @parser
    end
  end

end
