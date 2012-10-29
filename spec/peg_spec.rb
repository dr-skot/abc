$LOAD_PATH << './'

require 'polyglot'
require 'treetop'
require 'lib/abc/abc-2.0-draft4.treetop'
require 'lib/abc/syntax-nodes.rb'

describe "abc-2.0-draft4 PEG" do

  before do
    @parser = ABCParser.new
  end


  # HELPERS

  def parse(abc)
    p = @parser.parse abc
    p.should_not be(nil), @parser.failure_reason
    p.clean
    p
  end
  
  def fail_to_parse(abc)
    p = @parser.parse abc
    p.should == nil
    p
  end


  # TESTS

  it "accepts empty input" do
    p = parse ''
    p.is_a?(ABC::Tunebook).should == true
  end

  it "accepts a file header field" do
    p = parse "A:Beethoven\n"
    p.header.fields.count.should == 1
    p.header.fields[0].text_value.should == "A:Beethoven\n"
  end

  it "accepts a single tune field" do
    p = parse "X:1"
    p.header.should == nil
    p.tunes.count.should == 1
    p.tunes[0].header.fields.count.should == 1
    p.tunes[0].header.fields[0].text_value.should == "X:1"
  end

  it "separates fields" do
    p = parse "X:1\nT:Love Me Do"
    p.tunes[0].header.fields[0].text_value.should == "X:1\n"
    p.tunes[0].header.fields[1].text_value.should == "T:Love Me Do"
  end

  it "recognizes an info field" do
    p = parse "%%abc-copyright (c) ASCAP"
    p.header.fields.count.should == 1
    p.header.fields[0].is_a?(ABC::InfoField).should == true
    p.header.fields[0].text_value.should == "%%abc-copyright (c) ASCAP"
  end

  it "recognizes info fields in the file header" do
    p = parse "T:Title\n%%abc-copyright (c) ASCAP\nA:Author"
    p.header.fields.count.should == 3
    p.header.fields[1].is_a?(ABC::InfoField).should == true
    p.header.fields[1].text_value.should == "%%abc-copyright (c) ASCAP\n"
  end

  it "recognizes info fields in the tune header" do
    p = parse "X:1\n%%abc-copyright (c) ASCAP\nA:Author"
    p.tunes[0].header.fields.count.should == 3
    p.tunes[0].header.fields[1].is_a?(ABC::InfoField).should == true
    p.tunes[0].header.fields[1].text_value.should == "%%abc-copyright (c) ASCAP\n"
  end

  it "does not recognize info fields in the tune body" do
    fail_to_parse "X:1\n abc\n%%abc-copyright (c) ASCAP\ndef"
  end

  it "recognizes music" do
    parse "X:1\n abc"
  end

  it "accepts raw music with no headers" do
    parse "abc"
  end

  describe "note lengths" do
    it "accepts short and long notes" do
      parse "a2 b3/2 c3/ d/ d/2e//"
    end

    it "uses multiplier of 1 for empty note length" do
      p = parse "a"
      p.tunes[0].items[0].note_length.numerator.should == 1
      p.tunes[0].items[0].note_length.denominator.should == 1
    end

    it "correctly reads a simple note length multiplier" do
      p = parse "a3"
      p.tunes[0].items[0].note_length.numerator.should == 3
      p.tunes[0].items[0].note_length.denominator.should == 1
    end

    it "does not accept weirdo note lengths" do
      fail_to_parse "a//4"
      fail_to_parse "a3//4"
    end
  end

  it "accepts notes in various octaves" do
    parse "ABC abc a,b'C,,D'' e,', f'', G,,,,,'''"
  end

  it "accepts notes with accidentals" do
    parse "^A ^^a2 _b/ __C =D"
  end

  it "does not accept bizarro accidentals" do
    fail_to_parse "^_A"
    fail_to_parse "_^A"
    fail_to_parse "^^^A"
    fail_to_parse "=^A"
    fail_to_parse "___A"
    fail_to_parse "=_A"
  end

  it "accepts rests" do
    parse "z3/2 x// x2 Z4"
  end

  it "does not accept wierdo rest lengths" do
    fail_to_parse "Z3/2"
    fail_to_parse "z3//4"
  end

  it "accepts broken rhythm markers" do
    parse "a>b c<d a>>b c2<<d2"
  end

  it "does not accept broken rhythm weirdness" do
    fail_to_parse "a<>b"
    fail_to_parse "a><b"
  end

  it "accepts spacers" do
    parse "ab y de"
  end
  
  it "recognizes spaces as significant in music" do 
    p = parse "ab"
    p.tunes[0].items.count.should == 2
    p = parse "a   b"
    p.tunes[0].items.count.should == 3
    p.tunes[0].items[1].is_a?(ABC::TuneSpace).should == true
  end

  it "ignores backticks in tune body" do
    p = parse "a``b c3/`^d"
    p.tunes[0].items.map { |item| item.text_value }.join(',').should == 'a,b, ,c3/,^d'
  end

end
