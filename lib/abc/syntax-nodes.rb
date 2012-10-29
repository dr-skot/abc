require 'treetop'

class Treetop::Runtime::SyntaxNode

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

  class HeaderHaver < ABCNode
    def header
      child(Header)
    end
    def title
      header.values(/T/).join("\n")
    end
    def key
      header.fields(/K/)[-1].value
    end
  end
  
  class Tunebook < HeaderHaver
    def tunes
      children(Tune)
    end
  end
  
  class Header < ABCNode
    def fields(regex=nil)
      if regex
        children(Field).select { |f| f.label.text_value =~ regex }
      else
        children(Field)
      end
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
  class Key < ABCNode
  end

  # TUNE

  class Tune < HeaderHaver
    def items
      children(MusicNode)
    end
  end

  class TuneHeader < Header
  end

  class MusicNode < ABCNode
  end
  
  class TuneSpace < MusicNode
  end

  # NOTES AND RESTS
  
  class Note < MusicNode
  end

  class Pitch < MusicNode
    def octave
      note_letter.octave + octave_shift.value
    end
    def note
      note_letter.text_value.upcase
    end
    # half steps above C
    def height_in_octave(key={})
      height(key) % 12
    end
    # half steps above middle C
    # key is a hash that gives the sharps and flats of the key signature
    #   eg 'C'=>1 if C is sharp, 'E'=>-1 if E is flat
    def height(key={})
      key[note] = accidental.value if accidental.value
      12 * octave + "C D EF G A B".index(note) + (key[note] || 0)
    end
  end

  class Rest < MusicNode
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


  # BASICS

  class ABCString < ABCNode
  end

end
