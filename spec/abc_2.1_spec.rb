$LOAD_PATH << './'
require 'polyglot'
require 'treetop'
require 'lib/abc/abc-2.0-draft4.treetop'
require 'lib/abc/syntax-nodes.rb'
require 'lib/abc/parser.rb'
require 'lib/abc/voice.rb'
require 'lib/abc/measure.rb'
require 'lib/abc/meter.rb'
require 'lib/abc/key.rb'


describe "abc 2.1" do

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



  # 2.2 Abc file structure
  # An abc file consists of one or more abc tune transcriptions, optionally interspersed with free text and typeset text annotations. It may optionally start with a file header to set up default values for processing the file.
  # The file header, abc tunes and text annotations are separated from each other by empty lines (also known as blank lines).
  # An abc file with more than one tune in it is called an abc tunebook.
  
  describe "file structure" do
    it "must include at least 1 tune" do
      fail_to_parse ""
    end
    it "can consist of a single tune with no body" do
      p = parse "X:1\nT:Title\nK:C"
      p.is_a?(ABC::Tunebook).should == true
      p.tunes.count.should == 1
    end
    it "can consist of a single tune with a body" do
      p = parse "X:1\nT:Title\nK:C\nabc"
      p.tunes.count.should == 1
    end
    it "can consist of a several tunes with or without bodies" do
      p = parse "X:1\nT:Title\nK:C\nabc\n\nX:2\nT:T2\nK:D\n\nX:3\nT:T3\nK:none\ncba"
      p.tunes.count.should == 3
    end
    it "can include a file header" do
      p = parse "C:Madonna\nZ:me\n\nX:1\nT:Like a Prayer\nK:Dm"
      p.composer.should == "Madonna"
      p.transcriber.should == "me"
    end
    it "can include free text" do
      p = parse "free text\n\nX:1\nT:T\nK:C"
    end
    # TODO make sure badly formed tune or fileheader is not interpreted as free text
    it "can include typeset text annotations" do
      p = parse "N:fileheader\n\n%%text blah\n\nX:1\nT:T\nK:C"
      # TODO confirm that this is a text annotation and not free text
    end
  end

  # 2.3.1 Embedded abc fragment
  # An abc fragment is a partial abc tune. It may contain a partial tune header with no body or a tune body with optional tune header information fields.
  # Example 1: A fragment with no tune header:
  # <div class="abc-fragment">
  # CDEF GABc|
  # </div>
  # Example 2: A fragment with a partial tune header:
  # <div class="abc-fragment">
  # T:Major scale in D
  # K:D
  # DEFG ABcd|
  # </div>
  # Unless T:, M: and K: fields are present, a fragment is assumed to describe a stave in the treble clef with no title, no meter indication and no key signature, respectively.
  # An abc fragment does not require an empty line to mark the end of the tune body if it is terminated by the document markup.
  # Note for developers: For processing as an abc tune, the parsing code is notionally assumed to add empty X:, T: and K: fields, if these are missing. However, since the processing generally takes place internally within a software package, these need not be added in actuality.
  
  describe "fragment" do
    it "can contain a partial tune header with no body" do
      tune = parse_fragment "K:D"
      tune.key.tonic.should == "D"
      tune = parse_fragment "T:Love Stinks"
      tune.title.should == "Love Stinks"
      tune = parse_fragment "X:2"
      tune.refnum.should == 2
    end
    it "can contain a partial tune header with a body" do
      tune = parse_fragment "K:D\nabc"
      tune.key.tonic.should == "D"
    end
    it "can contain a tune body with no header" do
      parse_fragment "abc"
    end
    it "has a refnum of 1 if X field is missing" do
      tune = parse_fragment "abc"
      tune.refnum.should == 1
    end
    it "has the special key NONE if K field is missing" do
      tune = parse_fragment "abc"
      tune.key.should == Key::NONE
    end
    it "uses the treble clef if the K field is missing" do
      tune = parse_fragment "abc"
      tune.key.clef.name.should == "treble"
      # TODO tune itself should have a clef attribute
    end
    it "has nil title if T field is missing" do
      tune = parse_fragment "abc"
      tune.title.should == nil
      # TODO should it be "" instead?
    end
  end

end

