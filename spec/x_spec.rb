# -*- coding: utf-8 -*-

# TODO fields should be objects not nodes
# TODO get rid of label: on fields
# TODO change item.is_a?(Field) and item.label.text_value == 'K' to 
#    item.is_a?(Field, :type => :key)

require 'polyglot'
require 'treetop'

$LOAD_PATH.unshift File.expand_path('../lib')
require 'abc/parser'
include ABC


describe "abc 2.1:" do

  before do
    @parser = ABC::Parser.new
  end

  # for convenience
  def parse(input)
    p = @parser.parse(input)
    p.should_not be(nil), @parser.base_parser.failure_reason
    p.is_a?(ABC::Tunebook).should == true
    p
  end

  def fail_to_parse(input)
    p = @parser.parse(input)
    p.should == nil
    p
  end

  def parse_fragment(input)
    tune = @parser.parse_fragment(input)
    tune.should_not be(nil), @parser.base_parser.failure_reason
    tune.is_a?(ABC::Tune).should == true
    tune
  end

  def fail_to_parse_fragment(input)
    tune = @parser.parse_fragment(input)
    tune.should == nil
    tune
  end



end
