require 'treetop'

class Object
  def is_one_of?(*types)
    types.inject(false) { |result, type| result || self.is_a?(type) }
  end
  def is_a?(type, attributes={})
    super(type) && attributes.keys.inject(true) do |result, k|
      result && self.respond_to?(k) && self.send(k) == attributes[k]
    end
  end
end

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
          elements.map { |elem| elem.text_value_with_inclusions } * ""
        end
      end

      def values(*types)
        types << ValueNode if types.count > 0
        vals = children(*types).map { |el| el.is_a?(ValueNode) ? el.value : el }
        types.count == 0 ? vals : vals.select { |v| v.is_one_of? *types }
      end

      # returns the ABCNodes that are immediate descendants of this node
      # (immediate descendant meaning there may be intervening SyntaxNodes, but they are not ABCNodes)
      # or select from among these children by passing subclasses of ABCNode
      def children(*types)
        if types.count > 0
          children.select { |el| el.is_one_of? *types } 
        else
          elements ? elements.map { |el| el.is_a?(ABCNode) ? el : el.children }.flatten : []
        end
      end
      
      # returns the first child (of type, optionally) or nil if no children
      def child(type=nil)
        c = children(type)[0]
      end

      def value
        nil
      end

    end

  end
end
