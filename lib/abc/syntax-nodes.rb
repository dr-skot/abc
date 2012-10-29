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
  
  class Tunebook < ABCNode
    def header
      child(FileHeader)
    end
    def tunes
      children(Tune)
    end
  end
  
  class Header < ABCNode
    def fields
      children(Field)
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

  class Tune < ABCNode
    def header
      child(TuneHeader)
    end
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
    def height_in_octave
      height % 12
    end
    # half steps above middle C
    def height
      12 * octave + "C D EF G A B".index(note) + (accidental.value || 0)
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
