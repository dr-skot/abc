# TODO ties and slurs should disappear as music items, should be information on individual notes
# TODO tune.overlays? might also be useful if there are overlays in any measures
# TODO maybe also a list of these measures as measures_with_overlays
# TODO dotted bar should not make a new measure
# TODO data structure: tunes[t].measures[m].notes[n] note can be: note, chord, rest, !measure rest! which can make the measure several measures long
# TODO data structure: tunes[t].measures[m].items[i] item is any of the above plus spacer, dotted bar and fields
# TODO handle continuation lines with a preprocess

require 'treetop'


module Treetop

  module Runtime

    class ChristeningHash < Hash
      def []=(k, v)
        super(k, v)
        v.christen_once if v.respond_to?(:christen)
      end
    end

    class CompiledParser
      alias_method :instantiate_node_original, :instantiate_node
      def instantiate_node(node_type, *args)
        # puts node_type
        node = instantiate_node_original(node_type, *args)
        node.parser = self
        node
      end

      alias_method :prepare_to_parse_original, :prepare_to_parse
      def prepare_to_parse(input)
        prepare_to_parse_original(input)
        @node_cache = Hash.new {|hash, key| hash[key] = ChristeningHash.new}
      end
      
    end
    
    class SyntaxNode
      attr_accessor :parser
      attr_reader :inclusion
      
      def christen_once
        christen unless @christened
        @christened = true
      end

      def text_value_with_inclusions
        if inclusion
          inclusion
        elsif terminal?
          text_value
        else
          elements.map { |elem| elem.text_value_with_inclusions }.join("")
        end
      end

    end
    
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
    :area => /A/,
    :book => /B/,
    :composer => /C/,
    :disc => /D/,
    :discography => /D/,
    :file_url => /F/,
    :url => /F/, 
    :group => /G/,
    :history => /H/,
    :notations => /N/,
    :origin => /O/,
    :rhythm => /R/,
    :remark => /r/,
    :source => /S/,
    :title => /T/,
    :transcription => /Z/,
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

  class ABCSection < ABCNode
  end

  class TypesetText < ABCSection
  end

  class FreeText < ABCSection
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

    def field_value(label)
      return nil unless header
      if label
        values = header.values(label)
        if values.count == 0 
          master_node.field_value(label) if master_node
        elsif values.count == 1
          values[0]
        else
          values
        end
      end
    end

    def instructions
      if !@instructions
        @instructions = {}
        if header
          fields = header.fields(/I/)
          fields.each { |f| @instructions[f.name] = f.value }
        end
      end
      @instructions
    end
    
    def method_missing(meth, *args, &block)
      field_value(STRING_FIELDS[meth])
    end

    def meter
      if !@meter && header && (field = header.field(/M/))
        @meter = field.meter
      end
      @meter ||= Meter.new :free
    end
  end
  
  class Tunebook < NodeWithHeader
    def sections
      children.select { |c| c.is_a?(Tune) || c.is_a?(ABCSection) }
    end
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
    def assign_free_text
      free_text = nil
      children.each do |child|
        if child.is_a? FreeText
          free_text = child.text
        elsif child.is_a? Tune
          child.free_text = free_text
          free_text = nil
        end
      end
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
      fields(regex).map { |f| f.value }
    end
    def value(regex)
      if (f = field(regex))
        f.value
      else
        nil
      end
    end
  end

  class FileHeader < Header
  end

  # FIELDS

  class Field < ABCNode
    def value
      if content.respond_to? :value
        content.value
      elsif content.respond_to? :text_value
        content.text_value
      else
        content
      end
    end
  end

  class InfoField < Field
  end


  # TUNE

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
        all_items = children.select { |c| c.is_a?(MusicNode) || c.is_a?(Field) || c.is_a?(TuneLineBreak) || c.is_a?(SymbolLine) }
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
      children.select { |child| child.is_a?(MusicNode) || child.is_a?(Field) }
    end
    def notes
      if @first_voice
        @first_voice.notes
      else
        all_notes
      end
    end
    def all_notes
      items.select { |item| item.is_a?(NoteOrRest) }
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
    def apply_symbol_lines
      lines.each do |line|
        if line && line.symbols
          items = line.items
          i = 0
          line.symbols.each do |symbol|
            break if i >= items.count
            if symbol.skip == :note
              # advance to next note, then skip it
              i += 1 until items.count <= i || items[i].is_a?(NoteOrRest)
              i += 1
            elsif symbol.skip == :bar
              # advance to next (undotted) bar, then skip it
              i += 1 until items.count <= i || items[i].is_a?(BarLine) && items[i].type != :dotted
              i += 1
            else
              # find next note and set this symbol on it
              i += 1 until items.count <= i || items[i].is_a?(NoteOrRest)
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
              i += 1 until items.count <= i || items[i].is_a?(NoteOrRest)
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
  end

  class TuneLine
    attr_reader :items
    attr_accessor :symbols
    attr_accessor :lyrics
    attr_accessor :hard_break
    def initialize(items=[], hard_break=false)
      @items = items
      @hard_break = hard_break
    end
    def hard_break?
      @hard_break
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

  # SYMBOL LINE
  class SymbolLine < ABCNode
  end

  class SymbolUnit < ABCNode
    def skip
      :none
    end
  end

  # LYRICS
  class LyricsLine < Field
  end

  class LyricUnit < ABCNode
  end

  # OVERLAY DELIMITER
  class OverlayDelimiter < MusicNode
  end


  # PARTS
  class PartsUnit < ABCNode
    def list
      parts = []
      reset
      while (p = next_part)
        parts << p
      end
      reset
      parts
    end
    def repeat
      if repeat_node && !repeat_node.empty?
        repeat_node.value
      else
        1
      end
    end
  end
  
  class PartSequence < PartsUnit
    def next_part
      @child_index ||= 0
      kids = children(PartsUnit)
      if @child_index < kids.count
        part = kids[@child_index].next_part
        if part
          part
        else
          @child_index += 1
          next_part
        end
      end
    end
    def reset
      @child_index = 0
      children(PartsUnit).each { |kid| kid.reset }
    end
  end
  
  class PartsGroup < PartsUnit
    def next_part
      @repeat_index ||= 0
      if @repeat_index < repeat
        part = parts.next_part
        if part
          part
        else
          @repeat_index += 1
          parts.reset
          next_part
        end
      end
    end
    def reset
      @repeat_index = 0
      parts.reset
    end
  end

  class PartsAtom < PartsUnit
    def next_part
      @index ||= 0
      if @index < repeat
        @index += 1
        part.text_value
      end
    end
    def reset
      @index = 0
    end
  end

  class InstructionField < Field
    def christen
      include_file(value) if name == 'abc-include'
    end
    def include_file(filename)
      @inclusion = IO.read(filename)
    end
  end

  # BASICS

  class ABCString < ABCNode
  end

end
