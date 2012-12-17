module ABC

  class Tunebook < HeaderedSection
    attr_reader :sections

    def sections
      @sections ||= children.select { |v| !v.is_a?(Header) }
    end

    def tunes
      @tunes ||= children(Tune)
    end

    def tune(refnum)
      tunes.select { |f| f.refnum == refnum }.last
    end

    def propagate_tunebook_header
      tunes.each { |tune| tune.master_node = self } if header
    end

    def apply_note_lengths
      tunes.each { |tune| tune.apply_note_lengths }
    end

    def apply_broken_rhythms
      tunes.each { |tune| tune.apply_broken_rhythms }
    end
    def apply_chord_lengths
      tunes.each { |tune| tune.apply_chord_lengths }
    end
    def apply_meter
      tunes.each { |tune| tune.apply_meter }
    end
    def apply_key_signatures
      tunes.each { |tune| tune.apply_key_signatures }
    end
    def apply_beams
      tunes.each { |tune| tune.apply_beams }
    end
    def apply_symbol_lines
      tunes.each { |tune| tune.apply_symbol_lines }
    end
    def apply_lyrics
      tunes.each { |tune| tune.apply_lyrics }
    end
    def divvy_voices
      tunes.each { |tune| tune.divvy_voices }
    end
    def divvy_parts
      tunes.each { |tune| tune.divvy_parts }
    end
    def collect_measures
      tunes.each { |tune| tune.collect_measures }
    end
    def apply_clefs
      tunes.each { |tune| tune.apply_clefs }
    end
    def apply_ties_and_slurs
      tunes.each { |tune| tune.apply_ties_and_slurs }
    end
    def apply_tuplets
      tunes.each { |tune| tune.apply_tuplets }
    end
    def apply_redefinable_symbols
      tunes.each { |tune| tune.apply_redefinable_symbols }
    end
  end

end
