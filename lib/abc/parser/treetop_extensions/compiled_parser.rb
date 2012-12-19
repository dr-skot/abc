# Extends Treetop::Runtime::CompiledParser so that it
# - gives each node a reference to the parser
# - christens new nodes after they are instantiated and extended
# - supports the input_changed? flag

require 'treetop'

module Treetop
  module Runtime

    class CompiledParser
      attr_accessor :input_changed
      alias_method :input_changed?, :input_changed

      alias_method :instantiate_node_original, :instantiate_node
      def instantiate_node(node_type, *args)
        node = instantiate_node_original(node_type, *args)
        node.parser = self
        node
      end

      # We can't do the christening in ::instantiate_node because we want
      # to call ::christen *after* the node has been extended with all its inline methods.
      # A suitable time for this is when the node is inserted into the @node_cache,
      # so we rig @node_cache to christen new entries via ChristeningHash (see below)
      alias_method :prepare_to_parse_original, :prepare_to_parse
      def prepare_to_parse(input)
        prepare_to_parse_original(input)
        @node_cache = Hash.new { |hash, key| hash[key] = ChristeningHash.new }
      end

      def alias_rule(new_rule, orig_rule)
        metaclass = class << self; self; end;
        metaclass.send(:alias_method, "_nt_#{new_rule}", "_nt_#{orig_rule}")
      end
      
    end

    class ChristeningHash < Hash
      def []=(k, v)
        super(k, v)
        v.christen_once if v.respond_to?(:christen)
      end
    end

  end
end
