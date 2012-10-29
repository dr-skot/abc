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
    def self.clean_tree(root)
      return nil unless root
      # first get the clean children
      children = []
      if root.elements
        children = root.elements.reduce([]) do |result, node| 
          nodes = clean_tree node
          result += nodes if nodes
          result
        end
      end
      
      if root.class.name == "Treetop::Runtime::SyntaxNode"
        # remove generic class, promoting children if any
        if children.size == 0
          nil
        else
          children
        end
      else
        # use clean children as elements
        if root.elements
          root.elements.clear
          root.elements.push *children
        end
        [root]
      end
    end

    def clean
      ABCNode.clean_tree(self)
    end
    
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
  end

  class Rest < MusicNode
  end

  class NoteLength < MusicNode
=begin
    attr_reader :numerator
    attr_reader :denominator
    def initialize(input, interval=(0..input.length-1), elements = nil)
      super(input, interval, elements)
      @numerator = 1
      @denominator = 1
      m = text_value.match(/(\d*)(\/*)(\d*)/)
      num, slashes, den = m[1], m[2], m[3]
      @numerator = num.to_i if num != ""
      @denominator = den.to_i if den != ""
      @denominator *= 2**slashes.length if slashes.length > 0 && den == ""
    end
=end
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
