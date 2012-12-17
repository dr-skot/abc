module ABC

  class Overlay < Part
  end

  class Voice < Part
    attr_accessor :name
    attr_accessor :subname
    attr_accessor :stem
    attr_accessor :clef
    attr_accessor :measures

    alias_method :bars, :measures

    def initialize(id=nil, opts={})
      super(id)
      @name = opts[:name]
      @subname = opts[:subname]
      @stem = opts[:stem] if opts[:stem]
      @measures = []
    end

    def apply_note_lengths(start_note_length)
      len = start_note_length
      items.each do |item|
        if item.is_a?(MusicUnit)
          item.unit_note_length = len
        elsif item.is_a?(Field, :type => :unit_note_length)
          len = item.value
        end
      end
    end

    def apply_broken_rhythms(note_set=notes)
      last_note = nil
      note_set.each do |it|
        if (br = it.broken_rhythm_marker)
          # TODO throw an error if no last note?
          last_note.broken_rhythm *= br.change('<') if last_note
          it.broken_rhythm *= br.change('>')
        end
        apply_broken_rhythms(it.grace_notes.notes) if it.is_a?(NoteOrChord) && it.grace_notes
        last_note = it
      end
    end

    def collect_measures
      measures << (measure = Measure.new)
      elements.each do |element|
        if element.is_a? BarLine
          if measure == measures[0] && measure.empty?
            # left bar on first measure shouldn't make a new measure
            measure.left_bar = element
          else
            # new measure
            measure.right_bar = element
            (measure = Measure.new).left_bar = element
            measures << measure
          end
        elsif element.type == :overlay_delimiter
          measure.overlays << Overlay.new
        else
          (measure.overlays? ? measure.overlays.last : measure).elements << element
        end
      end
    end

    def apply_clefs(tune_clef)
      current_clef = clef || tune_clef
      items.each do |item|
        if item.respond_to?(:pitch) && item.pitch
          item.pitch.clef = current_clef
        elsif item.respond_to?(:notes) # a chord
          item.notes.each { |note| note.pitch.clef = current_clef }
        elsif item.is_a?(Field, :type => :key)
          # only change clefs if a clef was specified
          current_clef = item.value.clef if item.value.clef != Clef::DEFAULT 
        end
      end
    end

    def apply_key_signatures(key)
      base_signature = key.signature.dup
      signature = base_signature
      items.each do |item|
        if item.respond_to?(:grace_notes) && item.grace_notes
          item.grace_notes.notes.each { |n| n.pitch.signature = signature }
        end
        if item.respond_to?(:pitch) && item.pitch
          item.pitch.signature = signature
          # note's accidental may have altered the signature so ask for it back
          signature = item.pitch.signature
        elsif item.respond_to?(:notes)
          item.notes.each do |note|
            note.pitch.signature = signature
            signature = note.pitch.signature
          end
        elsif item.is_a?(BarLine) && !item.dotted?
          # reset to base signature at end of each measure
          signature = base_signature
        elsif item.is_a?(Field, :type => :key)
          # key change
          base_signature = item.value.signature.dup
          signature = base_signature
        end
      end
    end

    def apply_meter(meter)
      items.each do |item|
        if item.is_a? MeasureRest
          item.measure_length = meter.measure_length if meter
        elsif item.is_a?(TupletMarker)
          item.compound_meter = meter.compound? if meter
        elsif item.is_a?(Field, :type => :meter)
          meter = item.value
        end
      end
    end

    def apply_lyrics
      verse_start = 0 # index to reset to for new verse if any
      i = 0 #index of where to set current lyric
      j = 0 #index of lyric line (when i >= j stop setting lyrics)
      elements.each_with_index do |element, index|
        if element.is_a?(LyricsLine)
          i = j
          j = index
          element.units.each do |unit|
            break if i >= j # stop setting lyrics at lyric line
            if unit.is_a?(SymbolSkip, :type => :note)
              # advance to next note, then skip it
              i += 1 until i >= j || elements[i].is_a?(MusicUnit)
              i += 1
            elsif unit.is_a?(SymbolSkip, :type => :bar)
              # advance to next (undotted) bar, then skip it
              i += 1 until i >= j || (elements[i].is_a?(BarLine) && !elements[i].dotted?)
              i += 1
            else
              # find next note and set this lyric on it
              i += 1 until i >= j || elements[i].is_a?(MusicUnit);
              elements[i].lyric = unit if i < j
              # how many notes does it apply to?
              note_count = unit.note_count
              # advance that many notes
              while i < j && note_count > 1
                note_count -= 1 if elements[i].is_a?(MusicUnit)
                i += 1
              end
              # then advance to next element
              i += 1
            end
          end
        end
      end
    end

  end
end
