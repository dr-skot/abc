module ABC

  class Overlay
    attr_accessor :notes
    def initialize
      @notes = []
    end
  end

  class Voice
    attr_accessor :id
    attr_accessor :name
    attr_accessor :subname
    attr_accessor :stem
    attr_accessor :clef
    attr_accessor :items
    attr_accessor :measures

    alias_method :bars, :measures

    def initialize(id, opts={})
      @id = id
      @name = opts[:name]
      @subname = opts[:subname]
      @stem = opts[:stem] if opts[:stem]
      @items = []
      @measures = []
    end

    def notes
      items.select { |item| item.is_a?(MusicUnit) }
    end

    def collect_measures
      measure = Measure.new
      measures << measure
      overlay = nil
      items.each do |item|
        if item.is_a? BarLine
          # special case: left bar on first measure is optional, don't make a new measure if it's there
          if measure == measures[0] && measure.items.count == 0 && measure.left_bar == nil
            measure.left_bar = item
          else
            measure.right_bar = item
            measure = Measure.new
            measure.left_bar = item
            measures << measure
            overlay = nil
          end
        elsif item.is_a? OverlayDelimiter
          overlay = Overlay.new
          measure.overlays << overlay
        elsif overlay
          overlay.notes << item if item.is_a?(MusicUnit)
          # TODO add assertion? no other type of item should be possible here
        else
          measure.items << item
        end
      end
    end

    def apply_clefs(tune_clef)
      current_clef = clef || tune_clef
      items.each do |item|
        if item.respond_to?(:pitch) && item.pitch
          item.pitch.clef = current_clef
        elsif item.respond_to?(:notes) # a chord
          item.notes.each do |note|
            note.pitch.clef = current_clef
          end
        elsif item.is_a?(Field, :type => :key)
          # only change clefs if a clef was specified
          key_clef = item.value.clef
          current_clef = key_clef if key_clef != Clef::DEFAULT 
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
        elsif item.is_a?(BarLine) && item.type != :dotted
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
      if meter && measure_length = meter.measure_length
        items.each do |item|
          if item.is_a? MeasureRest
            item.measure_length = measure_length
          elsif item.is_a?(Field, :type => :meter)
            measure_length = item.value.measure_length
          end
        end
      end
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

  end
  
end
