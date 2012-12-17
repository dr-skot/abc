# TODO tune.overlays? might also be useful if there are overlays in any measures
# TODO maybe also a list of these measures as measures_with_overlays
# TODO dotted bar should not make a new measure
# TODO data structure: tunes[t].measures[m].notes[n] note can be: note, chord, rest, !measure rest! which can make the measure several measures long
# TODO data structure: tunes[t].measures[m].items[i] item is any of the above plus spacer, dotted bar and fields

module ABC
  class Tune < HeaderedSection

    attr_reader :first_voice

    def refnum
      num = header.value(:refnum) || 1
      num == "" ? nil : num
    end

    def clef
      key.clef
    end

    def key
      @key ||= header.last_value(:key) || Key::NONE
    end

    def part_sequence
      header.last_value(:part_sequence) 
    end

    def tempo
      header.last_value(:tempo)
    end

    def unit_note_length
      @unit_note_length ||= header.last_value(:unit_note_length) || meter.default_unit_note_length
    end

    def unaligned_lyrics
      header.value(:unaligned_lyrics)
    end
    alias_method :words, :unaligned_lyrics

    def redefinable_symbols
      @redefinable_symbols ||= 
        header.values(:user_defined).inject(REDEFINABLE_SYMBOLS.dup) do |result, embellishment| 
        result.merge!(embellishment.shortcut => embellishment)
      end
    end

    def voices
      @voices ||= header.values(:voice).inject({}) do |voices, voice|
        @first_voice = voice if !@first_voice
        voices.merge!(voice.id => voice)
      end
    end

    def many_voices?
      return voices.count > 1
    end

    def all_elements
      @all_elements ||= children.select { |child| !child.is_a?(Header) }
    end
    
    def all_items
      @all_items ||= children(MusicElement)
    end
    
    def all_notes
      @all_notes ||= children(MusicUnit)
    end
    
    def elements
      first_voice ? first_voice.elements : all_elements
    end
    
    def items
      first_voice ? first_voice.items : all_items
    end
    
    def notes
      first_voice ? first_voice.notes : all_notes
    end
    
    def measures
      first_voice.measures if first_voice
    end
    alias_method :bars, :measures

    def postprocess
      divvy_voices
      divvy_parts
      apply_note_lengths
      apply_broken_rhythms
      apply_ties_and_slurs
      apply_beams
      apply_meter
      apply_tuplets
      apply_key_signatures
      apply_clefs
      apply_symbol_lines
      apply_redefinable_symbols
      apply_lyrics
      collect_measures
      self
    end

    def divvy_voices
      voice = nil
      all_elements.each do |element|
        if element.is_a?(Field, :type => :voice_marker)
          id = element.value
          voice = (voices[id] ||= Voice.new(id))
          @first_voice ||= voice
        end
        # create default voice if necessary
        voice ||= (@first_voice ||= voices[""] = Voice.new(""))
        voice.elements << element
        element.voice = voice
      end
    end

    def divvy_parts
      # use first part in part sequence as first_part
      if part_sequence
        part_sequence.reset
        part_id = part_sequence.next_part
        @first_part = parts[part_id] = Part.new(part_id) if part_id
        part_sequence.reset
      end
      part = nil
      elements.each do |element|
        if element.is_a?(Field, :type => :part_marker)
          id = element.value
          part = (parts[id] ||= Part.new(id))
          @first_part ||= part
        else
          # create default part if necessary
          part ||= (@first_part ||= parts[""] = Part.new(""))
          part.elements << element
          element.part = part
        end
      end
    end
    
    def apply_note_lengths
      tempo.unit_length = unit_note_length if tempo
      voices.each_value { |v| v.apply_note_lengths(unit_note_length) }
    end

    def apply_broken_rhythms
      voices.each_value { |v| v.apply_broken_rhythms }
    end
    
    # TODO slurs and ties should not cross P: or V: boundaries
    def apply_ties_and_slurs
      tied_left, start_slur, start_dotted_slur = false, 0, 0
      last_note = nil
      all_elements.each do |item|
        if item.is_a?(NoteOrChord)
          item.start_slur = start_slur
          item.start_dotted_slur = start_dotted_slur
          item.tied_left = tied_left
          last_note = item
          tied_left, start_slur, start_dotted_slur = false, 0, 0
        elsif item.is_a?(ABCElement, :type => :start_slur)
          start_slur += 1
        elsif item.is_a?(ABCElement, :type => :start_dotted_slur)
          start_dotted_slur += 1
        elsif item.is_a?(ABCElement, :type => :end_slur)
          last_note.end_slur += 1
        elsif item.is_a?(ABCElement, :type => :tie)
          last_note.tied_right = true
          tied_left = true
        elsif item.is_a?(ABCElement, :type => :dotted_tie)
          last_note.tied_right_dotted = true
          tied_left = true
        end
      end
    end

    # TODO beams should not cross P: or V: boundaries
    # must be done after notes know their lengths
    def apply_beams
      beam = :start
      last_note = nil
      all_elements.each do |item|
        if item.is_a?(NoteOrChord) && item.length <= Rational(1, 8)
          item.beam = beam
          beam = :middle
          last_note = item
        else
          last_note.beam = (last_note.beam == :middle ? :end : nil) if last_note
          beam = :start
        end
      end
    end

    def apply_meter
      voices.each_value { |v| v.apply_meter(meter) }
    end

    def apply_tuplets
      tuplet_ratio = 1
      tuplet_notes = 0
      tuplet_marker = nil
      items.each do |item|
        if item.is_a?(TupletMarker)
          tuplet_notes = item.num_notes
          tuplet_ratio = item.ratio
          tuplet_marker = item
        elsif item.is_a?(MusicUnit) && tuplet_notes > 0
          item.tuplet_ratio = tuplet_ratio
          tuplet_notes -= 1
          if tuplet_marker
            # place marker on the first note
            item.tuplet_marker = tuplet_marker
            tuplet_marker = nil
          end
        end
      end
    end

    def apply_key_signatures
      voices.each_value { |v| v.apply_key_signatures(key) }
    end

    def apply_clefs
      voices.each_value { |v| v.apply_clefs(clef) }
    end

    def apply_redefinable_symbols
      symbols = redefinable_symbols
      items.each do |it|
        if it.is_a?(Field, :type => :user_defined)
          symbols[it.value.shortcut] = it.value
        else
          it.apply_redefinable_symbols(symbols)
        end
      end
    end


    def parts
      @parts ||= {}
    end

    def next_part
      p = part_sequence.next_part
      parts[p]
    end

    def apply_symbol_lines
      lines.each do |line|
        if line && line.symbol_lines != []
          items = line.items
          line.symbol_lines.each do |symbol_line|
            i = 0
            symbol_line.symbols.each do |symbol|
              break if i >= items.count
              if symbol.is_a?(SymbolSkip, :type => :note)
                # advance to next note, then skip it
                i += 1 until items.count <= i || items[i].is_a?(MusicUnit)
                i += 1
              elsif symbol.is_a?(SymbolSkip, :type => :bar)
                # advance to next (undotted) bar, then skip it
                i += 1 until items.count <= i || (items[i].is_a?(BarLine) && !items[i].dotted?)
                i += 1
              else
                # find next note and set this symbol on it
                i += 1 until items.count <= i || items[i].is_a?(MusicUnit)
                if i < items.count
                  items[i].embellishments << symbol
                  i += 1
                end
              end
            end
          end
        end
      end
    end

    def apply_lyrics
      voices.each_value { |v| v.apply_lyrics }
    end

    def collect_measures
      voices.each_value { |v| v.collect_measures }
    end

    def lines
      if !@lines
        line = TuneLine.new
        @lines = [line]
        all_items = children(Field, MusicLineBreak, SymbolLine, LyricsLine, MusicElement, ABCElement)
        all_items.each do |it|
          if it.type == :soft_linebreak || it.type == :hard_linebreak
            line = TuneLine.new
            line.hard_break = it.type == :hard_linebreak
            @lines << line
          elsif it.is_a?(SymbolLine)
            @lines[-2].symbol_lines << it if @lines.count > 1
          elsif it.is_a?(LyricsLine)
            @lines[-2].lyrics_lines << it if @lines.count > 1
          else
            line.items << it
          end
        end
        @lines.pop if @lines[-1].items.count == 0
      end
      @lines
    end

  end
end