require 'treetop'

module Treetop
  module Runtime

    class SyntaxNode
      attr_accessor :parser
      attr_reader :inclusion
      
      def christen_once
        christen if !@christened and respond_to? :christen
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

      # returns the ABCNodes that are immediate descendants of this node
      # (immediate descendant meaning there may be intervening SyntaxNodes, but they are not ABCNodes)
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

  end
end
