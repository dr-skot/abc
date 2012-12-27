module ABC
  class MacroFieldNode < FieldNode

    def process_text(s)
      s.gsub(regexp) do
        if (pitch = $1)
          replacement.gsub(/[h-z]/) { transpose_pitch(pitch, $&) }
        else
          replacement
        end
      end
    end

    def regexp
      # replace all n's with a regexp that matches any pitch sans accidentals
      @regexp ||= Regexp.new(Regexp.escape(target).gsub('n', "([A-Ga-g][,']*)"))
    end

    def transpose_pitch(pitch, transpose_letter)
      diff = transpose_letter.unpack("H*")[0].to_i(16) - "n".unpack("H*")[0].to_i(16)
      letter, octave = split_pitch(pitch)
      index = "CDEFGAB".index(letter) + diff
      unsplit_pitch("CDEFGAB"[index % 7], octave + index / 7)
    end

    def split_pitch(pitch)
      letter = pitch[0]
      octave_shift = pitch[1..-1]
      octave = octave_shift.count("'") - octave_shift.count(",") + (letter =~ /[A-G]/ ? 0 : 1)
      [letter.upcase, octave]
    end

    def unsplit_pitch(letter, octave)
      octave > 0 ? letter.downcase + ("'" * (octave-1)) : letter + ("," * -octave)
    end

  end
end
