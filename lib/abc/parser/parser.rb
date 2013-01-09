
module ABC

  REDEFINABLE_SYMBOLS = {
    '.' => Decoration.new('staccato', '.'),
    '~' => Decoration.new('roll', '~'),
    'T' => Decoration.new('trill', 'T'),
    'H' => Decoration.new('fermata', 'H'),
    'L' => Decoration.new('emphasis', 'L'),
    'M' => Decoration.new('lowermordent', 'M'),
    'P' => Decoration.new('uppermordent', 'P'),
    'S' => Decoration.new('segno', 'S'),
    'O' => Decoration.new('coda', 'O'),
    'u' => Decoration.new('upbow', 'u'),
    'v' => Decoration.new('downbow', 'v'),
  }


  class Parser

    def parse(input, options = {})
      @parser = ABCParser.new
      p = @parser.parse(input, options)
      if p
        input_with_inclusions = p.text_value_with_inclusions
        if input != input_with_inclusions
          parse(input_with_inclusions, options)
        else
          input_with_macros = p.text_value_with_macros
          if input != input_with_macros
            parse(input_with_macros, options)
          else
            # puts "warnings #{p.warnings}"
            p.value.postprocess
            p
          end
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
