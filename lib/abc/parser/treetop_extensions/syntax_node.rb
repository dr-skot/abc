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

    class Error
      attr_reader :message
      def initialize(syntax_node, message)
        @node = syntax_node
        @message = syntax_node.error
      end
      def input
        @input ||= @node.input[@node.interval]
      end
    end

    class SyntaxNode
      attr_accessor :parser
      attr_reader :inclusion
      attr_accessor :with_macros
      attr_reader :error
      attr_reader :warning

      # default value is nil
      def value
        nil
      end

      def element_values
        elements.map { |el| el.value }
      end
      
      # convenience for collecting lists
      # for example a list of things might be specified by the rule
      #   first:thing rest:(delimiter item:thing)*
      # this returns a list of those things, provided first, rest, and item are so defined
      def items
        rest.elements.inject([first]) { |list, el| list << el.item }
      end

      def item_values
        items.map { |it| it.value }
      end
      
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

      def text_value_with_macros
        if with_macros
          with_macros
        elsif terminal?
          text_value
        else
          elements.map { |elem| elem.text_value_with_macros } * ""
        end
      end

      def warnings
        w = warning ? [warning] : []
        terminal? ? w : elements.inject(w) { |w, el| w.concat(el.warnings) }
      end

      def errors
        err = error ? [Error.new(self, error)] : []
        terminal? ? err : elements.inject(err) { |err, el| err.concat(el.errors) }
      end

      def values(*types)
        if types.count > 0
          values.select { |el| el.is_one_of? *types }
        else
          next_descendants(ValueNode).map { |el| el.value }
        end
      end

      # returns the ABCNodes that are immediate descendants of this node
      # (immediate descendant meaning there may be intervening SyntaxNodes, but they are not ABCNodes)
      # or select from among these children by passing subclasses of ABCNode
      def children(*types)
        if types.count > 0
          children.select { |el| el.is_one_of? *types } 
        else
          next_descendants(ABCNode)
        end
      end

      def next_descendants(*types)
        if elements
          elements.map { |el| el.is_one_of?(*types) ? el : el.next_descendants(*types) }.flatten
        else
          []
        end
      end
      
      # returns the first child (of type, optionally) or nil if no children
      def child(type=nil)
        c = children(type)[0]
      end

    end

  end
end
