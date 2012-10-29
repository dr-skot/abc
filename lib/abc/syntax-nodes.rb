require 'treetop'

class Treetop::Runtime::SyntaxNode
  def keep_children?
    false
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
          if root.keep_children?
            result << node
          else
            nodes = clean_tree node
            result += nodes if nodes
          end
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

    def children(type)
      elements.select { |e| e.is_a? type } if elements
    end
    def child(type)
      c = children(type)
      c[0] if c && c.count > 0
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
      children(ABCNode).select { |e| !e.is_a?(Header) } if elements 
    end
  end

  class TuneHeader < Header
  end

  class TuneSpace < ABCNode
  end

  # NOTES AND RESTS
  
  class NoteElement < ABCNode
  end
  
  class Note < NoteElement
  end

  class Pitch < NoteElement
  end

  class Rest < NoteElement
  end

  class NoteLength < ABCNode
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

  class BrokenRhythm < ABCNode
  end

  class Spacer < ABCNode
  end


  # BASICS

  class ABCString < ABCNode
  end

end
