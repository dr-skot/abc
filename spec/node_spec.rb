$LOAD_PATH.unshift File.expand_path('../lib')
require 'abc/parser'

include Treetop::Runtime
include ABC

class SyntaxNode
  # add default values to initialize parameters, for easier testing
  alias_method :original_initialize, :initialize
  def initialize(input=' ', interval=(0..input.length-1), elements=nil)
    original_initialize(input, interval, elements)
  end
  # add factory method for creating a node with elements
  def self.node(elements)
    self.new ' ', 0..0, elements
  end
end

describe 'SyntaxNode' do

  it "can be initialized with one argument" do
    n = SyntaxNode.new 'input'
    n.should_not == nil
  end

  it "finds its children one level down" do
    c1 = ABCNode.new
    c2 = SyntaxNode.new
    c3 = ABCNode.new
    n = SyntaxNode.node [c1, c2, c3]
    n.children.should == [c1, c3]
  end

  it "finds its children two levels down" do
    c1 = ABCNode.new
    c2 = SyntaxNode.new
    c3 = ABCNode.new
    parent = SyntaxNode.node [c1, c2, c3]
    n = SyntaxNode.node [parent]
    n.children.should match_array [c1, c3]
  end

  it "finds its children at different levels down" do
    c1 = ABCNode.new 'c1'
    c2 = SyntaxNode.new 'c2'
    c3 = ABCNode.new 'c3'
    c4 = ABCNode.new 'c4'
    parent1 = SyntaxNode.node [c4]
    parent2 = SyntaxNode.node [c3]
    grandparent = SyntaxNode.node [c2, parent1]
    n = SyntaxNode.node [c1, grandparent, parent2]
    n.children.should match_array [c1, c3, c4]
  end

  it "doesn't find children of children" do
    c1 = ABCNode.new 'c1'
    c2 = ABCNode.node [c1]
    n = SyntaxNode.node [c2]
    n.children.should match_array [c2]
  end

  it "returns an empty list if childless" do
    n = SyntaxNode.new
    n.children.should == []
  end

  it "finds children of a given type" do
    c1 = FieldNode.new
    c2 = ABCNode.new
    c3 = FieldNode.new
    n = SyntaxNode.node [c1, c2, c3]
    n.children(FieldNode).should match_array [c1, c3]
  end

  it "finds one child of a given type" do
    c1 = FieldNode.new
    c2 = ABCNode.new
    c3 = FieldNode.new
    n = SyntaxNode.node [c1, c2, c3]
    n.child(FieldNode).should == c1
  end

  it "returns nil if childless and asked for a child" do
    n = SyntaxNode.new
    n.child(Tune).should == nil
  end

end
