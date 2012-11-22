require 'treetop'

class Object
  def try(method, *args)
    send method, args if respond_to? method
  end
end

class Array
  # http://stackoverflow.com/questions/4800337/split-array-into-sub-arrays-based-on-value
  def split
    result = [a=[]]
    each{ |o| yield(o) ? (result << a=[]) : (a << o) }
    result.pop if a.empty?
    result
  end
end

class Treetop::Runtime::SyntaxNode

  # TODO mother, descendants, left_sister, right_sister

  # returns the ABCNodes that are direct descendants of this node
  # (direct descendant meaning there may be intervening SyntaxNodes, but they are not ABCNodes)
  # or select from among these children by passing a subclass of ABCNode
  def children(type=nil)
    if type
      children.select { |el| el.is_a? type }
    else
      if !elements
        []
      else
        elements.map do |el|
          if el.is_a? ABC::ABCNode
            el
          else
            el.children
          end
        end.flatten
      end
    end
  end
  
  # returns the first child (of type, optionally) or nil if no children
  def child(type=ABC::ABCNode)
    c = children(type)[0]
  end

end

module ABC

  class Decoration
    attr_reader :symbol
    def initialize(symbol)
      @symbol = symbol
    end
    def type
      :decoration
    end
  end


  # these fields have unprocessed string values
  STRING_FIELDS = {
    :author => /A/,
    :book => /B/,
    :composer => /C/,
    :disc => /D/,
    :url => /F/, # (think F for file url)
    :group => /G/,
    :history => /H/,
    :comments => /N/,
    :origin => /O/,
    :rhythm => /R/,
    :remark => /r/,
    :source => /S/,
    :title => /T/,
    :transcriber => /Z/,
  }

  DEFAULT_USER_DEFINED_SYMBOLS = {
    '.' => Decoration.new('staccato'),
    '~' => Decoration.new('roll'),
    'T' => Decoration.new('trill'),
    'H' => Decoration.new('fermata'),
    'L' => Decoration.new('emphasis'),
    'M' => Decoration.new('lowermordent'),
    'P' => Decoration.new('uppermordent'),
    'S' => Decoration.new('segno'),
    'O' => Decoration.new('coda'),
    'u' => Decoration.new('upbow'),
    'v' => Decoration.new('downbow'),
  }

  # base class for ABC syntax nodes
  class ABCNode < Treetop::Runtime::SyntaxNode
  end

  class NodeWithHeader < ABCNode
    attr_accessor :master_node
    def header
      child(Header)
    end
    def info(label)
      fields = header.children(InfoField).select { |f| f.label == label } if header
      if fields && fields.count > 0
        fields.last.value
      else
        master_node.info(label) if master_node
      end
    end
    
    def method_missing(meth, *args, &block)
      if STRING_FIELDS[meth]
        values = header.values(STRING_FIELDS[meth])
        if values.count > 0 
          values.join("\n")
        else
          master_node.send(meth) if master_node
        end
      end
    end

    def meter
      if !@meter && header && (field = header.field(/M/))
        @meter = field.meter
      end
      @meter ||= Meter.new :free
    end
  end
  
  class Tunebook < NodeWithHeader
    def tunes
      children(Tune)
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
      tunes.each { |tune| tune.apply_meter(meter) }
    end
    def apply_key_signatures
      tunes.each { |tune| tune.apply_key_signatures }
    end
    def apply_beams
      tunes.each { |tune| tune.apply_beams }
    end
    def apply_lyrics
      tunes.each { |tune| tune.apply_lyrics }
    end
  end
  
  class Header < ABCNode
    # returns all header fields whose labels match regex
    def fields(regex=nil)
      if regex
        children(Field).select { |f| f.label.text_value =~ regex }
      else
        children(Field)
      end
    end
    #returns the last header field whose label matches
    def field(regex=nil)
      fields(regex)[-1]
    end
    # returns the values for all headers whose labels match regex
    def values(regex)
      fields(regex).map { |f| f.value.text_value }
    end
    def value(regex)
      if (f = field(regex))
        f.value.text_value
      else
        nil
      end
    end
  end

  class FileHeader < Header
  end

  # FIELDS

  class Field < ABCNode
  end

  class InfoField < Field
  end


  # TUNE

  class Tune < NodeWithHeader
    def refnum
      if header && (value = header.value(/X/))
        value.to_i
      else
        1
      end
    end
    def lines
      if !@lines
        @lines = []
        a = []
        is_hard_break = false
        all_items = children.select { |c| c.is_a?(MusicNode) || c.is_a?(Field) || c.is_a?(TuneLineBreak) }
        all_items.each do |it|
          if it.is_a?(TuneLineBreak)
            @lines << TuneLine.new(a, is_hard_break)
            is_hard_break = it.hard?
            a = []
          else
            a << it
          end
        end
      end
      @lines
    end
    def items
      children.select { |child| child.is_a?(MusicNode) || child.is_a?(Field) }
    end
    def notes
      items.select { |item| item.is_a?(NoteOrRest) }
    end
    def unit_note_length
      if !@unit_note_length && header && (field = header.field(/L/))
        @unit_note_length = field.value
      end
      @unit_note_length ||= meter.default_unit_note_length
    end
    def apply_note_lengths
      len = unit_note_length
      if tempo
        tempo.unit_length = len
      end
      items.each do |item|
        if item.is_a? NoteOrRest
          item.unit_note_length = len
        elsif item.is_a?(Field) && item.label.text_value == "L"
          len = item.value
        end
      end
    end
    def apply_broken_rhythms
      last_note = nil
      children(NoteOrRest).each do |item|
        if (br = item.broken_rhythm_marker)
          # TODO throw an error if no last note?
          last_note.broken_rhythm *= br.change('<') if last_note
          item.broken_rhythm *= br.change('>')
        end
        last_note = item
      end
    end
    def apply_chord_lengths
      items.each do |item|
        if item.respond_to?(:stroke) and item.stroke.is_a?(Chord)
          item.notes.each do |note|
            note.chord_length = item.note_length
          end
        end
      end
    end
    def apply_meter(tunebook_meter=nil)
      @meter = tunebook_meter if tunebook_meter && (!header || !header.field(/M/))
      if measure_length = meter.measure_length
        items.each do |item|
          if item.is_a? MeasureRest
            item.measure_length = measure_length
          elsif item.is_a?(Field) && item.label.text_value == "M"
            measure_length = item.meter.measure_length
          end
        end
      end
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
    def apply_key_signatures
      base_signature = key.signature.dup
      signature = base_signature
      items.each do |item|
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
        elsif item.is_a?(Field) && item.label.text_value == "K"
          # key change
          base_signature = item.key.signature.dup
          signature = base_signature
        end
      end
    end
    def apply_beams
      beam = :start
      last_note = nil
      children.each do |item|
        if item.is_a?(TuneSpace) || item.is_a?(BarLine) || item.is_a?(TuneLineBreak)
          beam = :start
          if last_note
            last_note.beam = nil if last_note.beam == :start
            last_note.beam = :end if last_note.beam == :middle
          end
        elsif item.is_a?(NoteOrRest)
          item.beam = beam
          beam = :middle
          last_note = item
        end
      end
    end
    def apply_lyrics
      last_line = nil
      waiting_for_bar = false
      lines.each do |line|
        if line.items[0].is_a?(Field) && line.items[0].label.text_value == 'w' && last_line
          units = line.items[0].units
          items = last_line.items
          i = 0
          units.each do |lyric|
            break if i >= items.count
            if lyric.skip == :note
              # advance to next note, then skip it
              i += 1 until items.count <= i || items[i].is_a?(NoteOrRest);
              i += 1
            elsif lyric.skip == :bar
              # advance to next (undotted) bar, then skip it
              i += 1 until items.count <= i || items[i].is_a?(BarLine) && items[i].type != :dotted
              i += 1
            else
              # find next note and set this lyric on it
              i += 1 until items.count <= i || items[i].is_a?(NoteOrRest);
              items[i].lyric = lyric if i < items.count
              # how many notes does it apply to?
              note_count = lyric.note_count
              # advance that many notes
              while i < items.count && note_count > 1
                note_count -= 1 if items[i].is_a?(NoteOrRest)
                i += 1
              end
              # then advance to next item
              i += 1
            end
          end
          # TODO propagate extra lyrics to next line?
        end
        last_line = line
      end
    end
    def voices
      if !@voices
        @voices = {}
        if header
          header.fields(/V/).each do |node|
            @voices[node.voice.id] = node.voice
          end
        end
      end
      @voices
    end
  end

  class TuneLine
    attr_reader :items
    def initialize(items, is_hard_break=false)
      @items = items
      @is_hard_break = is_hard_break
    end
    def hard_break?
      @is_hard_break
    end
    def notes
      items.select { |item| item.is_a?(NoteOrRest) }
    end
  end

  class TuneHeader < Header
  end

  class MusicNode < ABCNode
  end
  
  class TuneSpace < ABCNode
  end

  class TuneLineBreak < ABCNode
  end

  # NOTES AND RESTS

  # TODO rename this?
  class NoteOrRest < MusicNode
    attr_accessor :unit_note_length
    attr_accessor :broken_rhythm
    attr_accessor :chord_length
    attr_accessor :beam
    attr_accessor :lyric
    def unit_note_length
      @unit_note_length || 1
    end
    def broken_rhythm
      @broken_rhythm || 1
    end
    def chord_length
      @chord_length || 1
    end
    def note_length
      note_length_node.value * unit_note_length * broken_rhythm * chord_length
    end
  end
  
  class Note < NoteOrRest
  end

  class PitchNode < MusicNode
    def octave
      note_letter.octave + octave_shift.value
    end
    def note
      note_letter.text_value.upcase
    end

    def signature
      @signature ||= {}
    end
    # duplicates the signature if the note's accidental changes it
    def signature=(sig)
      if accidental && sig[note] != accidental
        @signature = sig.dup
        @signature[note] = accidental
      else
        @signature = sig
      end
      @signature
    end

    # half steps above C
    def height_in_octave(sig=signature)
      height(sig) % 12
    end
    # half steps above middle C
    def height(sig=signature)
      12 * octave + "C D EF G A B".index(note) + (accidental || sig[note] || 0)
    end
  end

  # TODO work this out so pseudopitch inherits from pitch or something
  class PseudoPitch
    attr_reader :note
    attr_reader :octave
    attr_reader :accidental
    def initialize(note, accidental=nil, octave=0)
      @note = note
      @octave = octave
    end
    def height
      12 * octave + "C D EF G A B".index(note) + (accidental || 0)
    end
  end

  class Rest < NoteOrRest
  end

  class MeasureRest < Rest
  end

  class NoteLength < MusicNode
    def multiplier
      1.0 * self.numerator / self.denominator
    end
  end

  class BrokenRhythm < MusicNode
  end

  # TIES AND SLURS

  class Tie < MusicNode
  end

  class Slur < MusicNode
  end

  class Spacer < MusicNode
  end

  # TUPLET MARKERS
  class TupletMarker < MusicNode    
  end

  # CHORDS
  class Chord < NoteOrRest
  end

  # BAR LINES
  class BarLine < MusicNode
  end

  # LYRICS
  class LyricUnit < ABCNode
  end

  # BASICS

  class ABCString < ABCNode
  end

end
