module ABC
  class Tune < NodeWithHeader
    attr_accessor :free_text
    def refnum
      if header && (value = header.value(/X/))
        if value == ""
          nil # TODO should this default to 1?
        else
          value.to_i
        end
      else
        1
      end
    end
    def lines
      if !@lines
        line = TuneLine.new
        @lines = [line]
        all_items = values(MusicNode, Field, TuneLineBreak, SymbolLine, MusicUnit)
        all_items.each do |it|
          if it.is_a?(TuneLineBreak)
            line = TuneLine.new
            line.hard_break = it.hard?
            @lines << line
          elsif it.is_a?(SymbolLine)
            @lines[-2].symbols = it.children(SymbolUnit) if @lines.count > 1
          elsif it.is_a?(LyricsLine)
            @lines[-2].lyrics = it.children(LyricUnit) if @lines.count > 1
          else
            line.items << it
          end
        end
        @lines.pop if @lines[-1].items.count == 0
      end
      @lines
    end
    def items
      if @first_voice
        @first_voice.items
      else
        all_items
      end
    end
    def all_items
      @all_items ||= values(MusicNode, Field, MusicUnit)
    end
    def notes
      if @first_voice
        @first_voice.notes
      else
        all_notes
      end
    end
    def all_notes
      values(MusicUnit)
    end
    def unit_note_length
      if !@unit_note_length && header && (field = header.field(/L/))
        @unit_note_length = field.value
      end
      @unit_note_length ||= meter.default_unit_note_length
    end
    def apply_note_lengths
      if tempo
        tempo.unit_length = unit_note_length
      end
      voices.each_value { |v| v.apply_note_lengths(unit_note_length) }
    end
    def apply_broken_rhythms
      last_note = nil
      all_notes.each do |item|
        if (br = item.broken_rhythm_marker)
          # TODO throw an error if no last note?
          last_note.broken_rhythm *= br.change('<') if last_note
          item.broken_rhythm *= br.change('>')
        end
        last_note = item
      end
    end
    def apply_meter(tunebook_meter=nil)
      @meter = tunebook_meter if tunebook_meter && !(header && header.field(/M/))
      voices.each_value { |v| v.apply_meter(meter) }
    end
    def tempo
      if !@tempo
        if header && (field = header.field(/Q/))
          @tempo = field.value
        else
          @tempo = nil # TODO NO_TEMPO
        end
      end
      @tempo
    end
    def key
      if !@key
        if header && (field = header.field(/K/))
          @key = field.key
        else
          @key = Key::NONE
        end
      end
      @key
    end
    def part_sequence
      if header && (field = header.field(/P/))
        field.value
      end
    end
    def parts
      @parts ||= {}
    end
    def next_part
      p = part_sequence.next_part
      parts[p]
    end
    def divvy_parts
      if part_sequence
        part_sequence.reset
        part_id = part_sequence.next_part
        @first_part = parts[part_id] = Part.new(part_id) if part_id
        part_sequence.reset
      end
      part = nil
      items.each do |item|
        # TODO lose text_value here, label should already be a string
        if item.is_a?(Field) && item.label.text_value == 'P'
          id = item.id
          parts[id] = Part.new(id) if !parts[id]
          part = parts[id]
          @first_part = part if !@first_part
        else
          if !part
            if !@first_part
              @first_part = parts[""] = Part.new("")  # create default part if necessary
            end
            part = @first_part
          end
          part.items << item
        end
      end
    end
    def apply_key_signatures()
        voices.each_value { |v| v.apply_key_signatures(key) }
    end
    def apply_beams
      beam = :start
      last_note = nil
      values.each do |item|
        if item.is_a?(TuneSpace) || item.is_a?(BarLine) || item.is_a?(TuneLineBreak)
          beam = :start
          if last_note
            last_note.beam = nil if last_note.beam == :start
            last_note.beam = :end if last_note.beam == :middle
          end
        elsif item.is_a?(MusicUnit)
          item.beam = beam
          beam = :middle
          last_note = item
        end
      end
    end
    def apply_symbol_lines
      lines.each do |line|
        if line && line.symbols
          items = line.items
          i = 0
          line.symbols.each do |symbol|
            break if i >= items.count
            if symbol.skip == :note
              # advance to next note, then skip it
              i += 1 until items.count <= i || items[i].is_a?(MusicUnit)
              i += 1
            elsif symbol.skip == :bar
              # advance to next (undotted) bar, then skip it
              i += 1 until items.count <= i || items[i].is_a?(BarLine) && items[i].type != :dotted
              i += 1
            else
              # find next note and set this symbol on it
              i += 1 until items.count <= i || items[i].is_a?(MusicUnit)
              if i < items.count
                items[i].annotations << symbol if symbol.type == :annotation
                items[i].decorations << symbol if symbol.type == :decoration
                items[i].chord_symbol = symbol.symbol if symbol.type == :chord_symbol
                i += 1
              end
            end
          end
        end
      end
    end
    def apply_lyrics
      lines.each do |line|
        if line && line.lyrics
          items = line.items
          i = 0
          line.lyrics.each do |lyric|
            break if i >= items.count
            if lyric.skip == :note
              # advance to next note, then skip it
              i += 1 until items.count <= i || items[i].is_a?(MusicUnit)
              i += 1
            elsif lyric.skip == :bar
              # advance to next (undotted) bar, then skip it
              i += 1 until items.count <= i || items[i].is_a?(BarLine) && items[i].type != :dotted
              i += 1
            else
              # find next note and set this lyric on it
              i += 1 until items.count <= i || items[i].is_a?(MusicUnit);
              items[i].lyric = lyric if i < items.count
              # how many notes does it apply to?
              note_count = lyric.note_count
              # advance that many notes
              while i < items.count && note_count > 1
                note_count -= 1 if items[i].is_a?(MusicUnit)
                i += 1
              end
              # then advance to next item
              i += 1
            end
            # TODO propagate extra lyrics to next line?
          end
        end
      end
    end
    def voices
      if !@voices
        @voices = {}
        if header
          header.fields(/V/).each do |node|
            @first_voice = node.voice if !@first_voice
            @voices[node.voice.id] = node.voice
          end
        end
      end
      @voices
    end
    def many_voices?
      return voices.count > 1
    end
    def divvy_voices
      voice = nil
      items.each do |item|
        # TODO lose text_value here, label should already be a string
        if item.is_a?(Field) && item.label.text_value == 'V'
          id = item.id
          voices[id] = Voice.new(id) if !voices[id]
          voice = voices[id]
          @first_voice = voice if !@first_voice
        else
          if !voice
            if !@first_voice
              @first_voice = voices[""] = Voice.new("")  # create default voice if necessary
            end
            voice = @first_voice
          end
          voice.items << item
        end
      end
    end
    def collect_measures
      voices.each_value { |v| v.collect_measures }
    end
    def measures
      @first_voice.measures
    end
    alias_method :bars, :measures
    def apply_clefs
      voices.each_value { |v| v.apply_clefs(clef) }
    end
    def clef
      key.clef
    end
  end
end
