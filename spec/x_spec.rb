# -*- coding: utf-8 -*-

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


  describe "the propagate-accidentals directive" do
    it "can specify no propagation at all" do
      p = parse_fragment "%%propagate-accidentals not\n_CCc|Cc"
      p.notes[0].pitch.height.should == -1
      p.notes[1].pitch.height.should == 0
      p.notes[2].pitch.height.should == 12
      p.notes[3].pitch.height.should == 0      
      p.notes[4].pitch.height.should == 12
    end
    it "can specify propagation within octave only" do
      p = parse_fragment "%%propagate-accidentals octave\n_CCc|Cc"
      p.notes[0].pitch.height.should == -1
      p.notes[1].pitch.height.should == -1
      p.notes[2].pitch.height.should == 12
      p.notes[3].pitch.height.should == 0      
      p.notes[4].pitch.height.should == 12
    end
    it "can specify propagation for all pitches" do
      p = parse_fragment "%%propagate-accidentals pitch\n_CCc|Cc"
      p.notes[0].pitch.height.should == -1
      p.notes[1].pitch.height.should == -1
      p.notes[2].pitch.height.should == 11
      p.notes[3].pitch.height.should == 0
      p.notes[4].pitch.height.should == 12
    end
    # TODO warning if any other value provided
  end
  

end
