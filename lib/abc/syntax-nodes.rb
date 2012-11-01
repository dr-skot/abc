require 'treetop'

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

  # base class for ABC syntax nodes
  class ABCNode < Treetop::Runtime::SyntaxNode
  end

  class NodeWithHeader < ABCNode
    def header
      child(Header)
    end
    def title
      header.values(/T/).join("\n")
    end
  end
  
  class Tunebook < NodeWithHeader
    def tunes
      children(Tune)
    end
    def apply_note_lengths
      tunes.each { |tune| tune.apply_note_lengths }
    end
    def apply_broken_rhythms
      tunes.each { |tune| tune.apply_broken_rhythms }
    end
    def apply_key_signatures
      tunes.each { |tune| tune.apply_key_signatures }
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
  end

  class FileHeader < Header
  end

  # FIELDS

  class Field < ABCNode
  end

  class InfoField < Field
  end

  # KEY
  class KeyNode < ABCNode
    def signature
      @key ||= Key.new tonic, mode, extra_accidentals
      @key.signature
    end
  end

  class DummyKeyNode < KeyNode
    attr_reader :tonic, :mode, :extra_accidentals
    def initialize
      @tonic = ""
      @mode = ""
      @extra_accidentals = {}
    end
  end

  NO_KEY = DummyKeyNode.new

  # TUNE

  class Tune < NodeWithHeader
    def items
      children.select { |child| child.is_a?(MusicNode) || child.is_a?(Field) }
    end
    def meter
      if !@meter && header && (field = header.field(/M/))
        @meter = field.meter
      end
      @meter ||= Meter.new :free
    end
    def unit_note_length
      if !@unit_note_length && header && (field = header.field(/L/))
        @unit_note_length = field.value
      end
      @unit_note_length ||= meter.default_unit_note_length
    end
    def apply_note_lengths
      len = unit_note_length
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
      change = nil
      items.each do |item|
        if item.is_a? BrokenRhythm
          # TODO throw an error if no last note?
          last_note.broken_rhythm *= item.change('<') if last_note
          change = item.change('>') # will apply this to next note
        elsif item.is_a? NoteOrRest
          if change
            item.broken_rhythm *= change
            change = nil
          end 
          last_note = item
        end
      end
    end
    def tempo
      if !@tempo
        @tempo = Tempo.new
      end
      @tempo
    end
    def key
      if !@key
        field = header.fields(/K/)[-1]
        if field
          @key = field.value
        else
          @key = NO_KEY
        end
      end
      @key
    end
    def apply_key_signatures
      base_signature = key.signature.dup
      signature = base_signature
      items.each do |item|
        if item.is_a? Note
          item.pitch.signature = signature
          # note's accidental may have altered the signature so ask for it back
          signature = item.pitch.signature
        elsif item.is_a? BarLine
          # reset to base signature at end of each measure
          signature = base_signature
        elsif item.is_a?(Field) && item.label.text_value == "K"
          # key change
          base_signature = item.value.signature.dup
          signature = base_signature
        end
      end
    end
  end

  class TuneHeader < Header
  end

  class MusicNode < ABCNode
  end
  
  class TuneSpace < MusicNode
  end

  # NOTES AND RESTS

  # TODO rename this?
  class NoteOrRest < MusicNode
    attr_accessor :unit_note_length
    attr_accessor :broken_rhythm
    def unit_note_length
      @unit_note_length || 1
    end
    def broken_rhythm
      @broken_rhythm || 1
    end
    def note_length
      note_length_node.value * unit_note_length * broken_rhythm
    end
  end
  
  class Note < NoteOrRest
  end

  class Pitch < MusicNode
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
      if accidental.value && sig[note] != accidental.value
        @signature = sig.dup
        @signature[note] = accidental.value
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
      12 * octave + "C D EF G A B".index(note) + (accidental.value || sig[note] || 0)
    end
  end

  class Rest < NoteOrRest
  end

  class NoteLength < MusicNode
    def multiplier
      1.0 * self.numerator / self.denominator
    end
  end

  class BrokenRhythm < MusicNode
  end

  class Spacer < MusicNode
  end

  # BAR LINES
  class BarLine < MusicNode
  end


  # BASICS

  class ABCString < ABCNode
  end

end
