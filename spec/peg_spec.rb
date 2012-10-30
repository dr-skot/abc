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
    # p.apply_key_signatures
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

  describe "header basics" do

    it "accepts a file header field" do
      p = parse "A:Beethoven\n"
      p.header.fields.count.should == 1
      p.header.fields[0].text_value.should == "A:Beethoven"
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
      p.tunes[0].header.fields[0].text_value.should == "X:1"
      p.tunes[0].header.fields[1].text_value.should == "T:Love Me Do"
    end
    
    it "differentiates file header from tune header" do
      p = parse "T:File\n\nX:1\nT:Tune"
      p.header.should_not == nil
      p.tunes.count.should == 1
      p.tunes[0].header.should_not == nil
    end
    
    it "supports inline fields in the tune body" do
      p = parse "X:1\nK:C\nabc[K:A]abc"
    end

  end

  it "supports multiple tunes" do
    p = parse "X:1\n\nX:2"
    p.tunes.count.should == 2
  end

  it "supports multiple tunes with music" do
    p = parse "X:1\nABC\n\nX:2\nDEF"
    p.tunes.count.should == 2
  end

  it "allows mulitple blank lines between tunes" do
    p = parse "X:1\nABC\n\n\n\nX:2\nDEF"
    p.tunes.count.should == 2
  end


  describe "fields" do
    it "parses title fields" do
      p = parse "T:File\nT:Subtitle\n\nX:1\nT:Godsavethequeen\n\nX:2\nT:Hailtothechief"
      p.title.should == "File\nSubtitle"
      p.tunes[0].title.should == "Godsavethequeen"
      p.tunes[1].title.should == "Hailtothechief"
    end
  end

  describe "key" do
    it "parses the tonic" do
      p = parse "K:Ebminor=e^c"
      p.tunes[0].key.tonic.should == "Eb"
    end
    it "parses the mode" do
      p = parse "K:Ebminor=e^c"
      p.tunes[0].key.mode.should == "minor"
      p = parse "K:A Mixolydian"
      p.tunes[0].key.mode.should == "Mixolydian"
    end
    it "parses the extra accidentals" do
      p = parse "K:Ebminor=e^c"
      p.tunes[0].key.extra_accidentals.should include 'E' => 0, 'C' => 1
    end

    it "delivers accidentals for major key" do
      p = parse "K:Eb"
      sig = p.tunes[0].key.signature
      sig.should include 'A' => -1, 'B' => -1, 'E' => -1
      sig.should_not include 'C', 'D', 'F', 'G'
    end

    it "delivers accidentals for key with mode" do
      p = parse "K:A# Phr"
      sig = p.tunes[0].key.signature
      sig.should include 'C' => 1, 'D' => 1, 'E' => 1, 'F' => 1, 'G' => 1, 'A' => 1
      sig.should_not include 'B'
    end

    it "delivers accidentals for key with extra accidentals" do
      p = parse "K:F =b ^C"
      sig = p.tunes[0].key.signature
      sig.should include 'C' => 1
      sig.should_not include %w{D E F G A B}
    end

  end

  describe "extended info fields" do

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

    it "does not accept weirdo note lengths" do
      fail_to_parse "a//4"
      fail_to_parse "a3//4"
    end

    it "uses multiplier of 1 for empty note length" do
      p = parse "a"
      p.tunes[0].items[0].note_length.numerator.should == 1
      p.tunes[0].items[0].note_length.denominator.should == 1
    end

    it "correctly reads a note length integer" do
      p = parse "a3"
      p.tunes[0].items[0].note_length.numerator.should == 3
      p.tunes[0].items[0].note_length.denominator.should == 1
    end

    it "correctly reads a note length fraction" do
      p = parse "a10/2"
      p.tunes[0].items[0].note_length.numerator.should == 10
      p.tunes[0].items[0].note_length.denominator.should == 2
    end

    it "correctly interprets note length slashes" do
      p = parse "a///"
      p.tunes[0].items[0].note_length.numerator.should == 1
      p.tunes[0].items[0].note_length.denominator.should == 8
    end

  end

  describe "octave" do

    it "accepts notes in various octaves" do
      parse "ABC abc a,b'C,,D'' e,', f'', G,,,,,'''"
    end

    it "correctly calculates the octave for note letters" do
      p = parse "CcAg"
      p.tunes[0].items[0].pitch.octave.should == 0
      p.tunes[0].items[1].pitch.octave.should == 1
      p.tunes[0].items[2].pitch.octave.should == -1
      p.tunes[0].items[3].pitch.octave.should == 1
    end
    
    it "shifts the octave up with apostrophes" do
      p = parse "C'c''"
      p.tunes[0].items[0].pitch.octave.should == 1
      p.tunes[0].items[1].pitch.octave.should == 3
    end

    it "shifts the octave down with commas" do
      p = parse "C,,,,c,,"
      p.tunes[0].items[0].pitch.octave.should == -4
      p.tunes[0].items[1].pitch.octave.should == -1
    end

    it "handles combinations of commas and apostrophes" do
      p = parse "C,',',,c,,'''',"
      p.tunes[0].items[0].pitch.octave.should == -2
      p.tunes[0].items[1].pitch.octave.should == 2
    end

  end

  describe "accidentals" do
    
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

    it "values sharps and flats accurately" do
      p = parse "^A^^a2_b/__C=DF"
      p.tunes[0].items[0].pitch.accidental.value.should == 1
      p.tunes[0].items[1].pitch.accidental.value.should == 2
      p.tunes[0].items[2].pitch.accidental.value.should == -1
      p.tunes[0].items[3].pitch.accidental.value.should == -2
      p.tunes[0].items[4].pitch.accidental.value.should == 0
      p.tunes[0].items[5].pitch.accidental.value.should == nil
    end
  end

  describe "pitch" do
    it "knows note name" do
      p = parse "C^Cd_e''F,',^^E'g'''__Ba,,,,b"
      p.tunes[0].items[0].pitch.note.should == 'C'
      p.tunes[0].items[1].pitch.note.should == 'C'
      p.tunes[0].items[2].pitch.note.should == 'D'
      p.tunes[0].items[3].pitch.note.should == 'E'
      p.tunes[0].items[4].pitch.note.should == 'F'
      p.tunes[0].items[5].pitch.note.should == 'E'
      p.tunes[0].items[6].pitch.note.should == 'G'
      p.tunes[0].items[7].pitch.note.should == 'B'
      p.tunes[0].items[8].pitch.note.should == 'A'
      p.tunes[0].items[9].pitch.note.should == 'B'
    end
    it "knows height in octave" do
      p = parse "C^^B,d_e''EF,',^^E'g'''_a__B,,,,^ab"
      0.upto 11 do |i|
        p.tunes[0].items[i].pitch.height_in_octave.should == i
      end
    end
    it "knows height" do
      p = parse "C^^B,d_e''EF,',"
      p.tunes[0].items[0].pitch.height.should == 0
      p.tunes[0].items[1].pitch.height.should == -11
      p.tunes[0].items[2].pitch.height.should == 14
      p.tunes[0].items[3].pitch.height.should == 39
      p.tunes[0].items[4].pitch.height.should == 4
      p.tunes[0].items[5].pitch.height.should == -7
    end

    it "knows height given a key signature" do
      p = parse "CD=DEF^FG_G"
      key = { 'C'=>1, 'D'=>1, 'F'=>1, 'G'=>1 } # E maj
      p.tunes[0].items[0].pitch.height(key).should == 1
      p.tunes[0].items[1].pitch.height(key).should == 3
      p.tunes[0].items[2].pitch.height(key).should == 2
      p.tunes[0].items[3].pitch.height(key).should == 4
      p.tunes[0].items[4].pitch.height(key).should == 6
      p.tunes[0].items[5].pitch.height(key).should == 6
      p.tunes[0].items[6].pitch.height(key).should == 8
      p.tunes[0].items[7].pitch.height(key).should == 6
      p = parse "AB=BCD^DE_E"
      key = { 'A'=>-1, 'B'=>-1, 'D'=>-1, 'E'=>-1 } # Ab maj
      p.tunes[0].items[0].pitch.height(key).should == -4
      p.tunes[0].items[1].pitch.height(key).should == -2
      p.tunes[0].items[2].pitch.height(key).should == -1
      p.tunes[0].items[3].pitch.height(key).should == 0
      p.tunes[0].items[4].pitch.height(key).should == 1
      p.tunes[0].items[5].pitch.height(key).should == 3
      p.tunes[0].items[6].pitch.height(key).should == 3
      p.tunes[0].items[7].pitch.height(key).should == 3
    end

  end

  describe "key signatures" do

    it "can apply the tune's key signature to a tune" do
      p = parse "K:F\nB"
      p.tunes[0].items[0].pitch.height.should == -1
      p.tunes[0].apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == -2
    end

    it "retains accidentals within a measure when applying key signature" do
      p = parse "K:F\nB=BB"
      p.tunes[0].apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == -2
      p.tunes[0].items[1].pitch.height.should == -1
      p.tunes[0].items[2].pitch.height.should == -1
    end

    it "can apply key signatures to all tunes in tunebook" do
      p = parse "K:Eb\nA=A^AA\n\nK:F\nB"
      p.apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == -4
      p.tunes[0].items[1].pitch.height.should == -3
      p.tunes[0].items[2].pitch.height.should == -2
      p.tunes[0].items[3].pitch.height.should == -2
      p.tunes[1].items[0].pitch.height.should == -2
    end

    it "does not apply key signature from previous tune" do
      p = parse "X:1\nK:Eb\nA\n\n\nX:2\nA"
      p.apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == -4
      p.tunes[1].items[0].pitch.height.should == -3
    end

    it "allows K:none" do
      parse "K:none"
    end

    it "changes key signature when inline K: field found in tune body" do
      p = parse "X:1\nK:C\nC[K:A]C"
      p.apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == 0
      p.tunes[0].items[2].pitch.height.should == 1
    end

    it "changes key signature when standalone K: field found in tune body" do
      p = parse "X:1\nK:C\nC\nK:A\nC"
      p.apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == 0
      p.tunes[0].items[2].pitch.height.should == 1
    end

  end

  describe "rests" do

    it "accepts rests" do
      parse "z3/2 x// x2 Z4"
    end
    
    it "does not accept wierdo rest lengths" do
      fail_to_parse "Z3/2"
      fail_to_parse "z3//4"
    end

    it "understands the note length of rests" do
      p = parse "z3/2x//z4"
      p.tunes[0].items[0].note_length.numerator.should == 3
      p.tunes[0].items[0].note_length.denominator.should == 2
      p.tunes[0].items[1].note_length.numerator.should == 1
      p.tunes[0].items[1].note_length.denominator.should == 4
      p.tunes[0].items[2].note_length.numerator.should == 4
      p.tunes[0].items[2].note_length.denominator.should == 1
    end

    it "understands measure-count rests" do
      p = parse "Z4"
      p.tunes[0].items[0].measure_count.should == 4
    end

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
