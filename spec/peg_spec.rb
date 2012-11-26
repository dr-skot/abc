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

    it "accepts no tune header fields after the K: field" do
      fail_to_parse "K:C\nA:Author\nabc"
    end

    it "can handle a standalone body field right after the K: field" do
      p = parse "K:C\nK:F\nabc"
      p.tunes[0].key.tonic.should == "C"
      p.tunes[0].items[0].key.tonic.should == "F"
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
    it "knows the refnum field" do
      p = parse "X:2\nabc\n\nX:37\nABC"
      p.tunes[0].refnum.should == 2
      p.tunes[1].refnum.should == 37
      p.tune(2).should == p.tunes[0]
      p.tune(37).should == p.tunes[1]
    end
    it "defaults to 1" do
      p = parse "ABC"
      p.tunes[0].refnum.should == 1
      p.tune(1).should = p.tunes[0]
    end
    # TODO: if more than one song, all songs must have an X field
    # or should it see the new song as plaintext??
    # it "requires the X field if more than one song" do
      # fail_to_parse("X:1\nabc\n\nK:Em\nefg")
    # end

    it "knows the string fields" do
      %w{Aauthor Bbook Ccomposer Ddisc Furl Ggroup Hhistory Ncomments Oorigin 
         Rrhythm rremark Ssource Ttitle Ztranscriber}.each do |field|
        label = field[0]
        name = field[1..-1]
        p = parse "#{label}:File Header\n\nX:1\n\nX:2\n#{label}:Tune Header\n#{label}:again"
        p.propagate_tunebook_header
        p.send(name).should == "File Header"
        p.tunes[0].send(name).should == "File Header"
        p.tunes[1].send(name).should == "Tune Header\nagain"
      end
    end

    it "allows meter fields in the file header" do
      p = parse "M:3/4"
      p.meter.measure_length.should == Rational(3, 4)
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

    it "allows K:none" do
      p = parse "K:none"
      p.tunes[0].key.tonic.should == ""
      p.tunes[0].key.mode.should == ""
      p.tunes[0].key.signature.should == {}
    end

  end

  describe "extended info fields" do

    it "recognizes an info field in the title header" do
      p = parse "%%abc-copyright (c) ASCAP\n\nX:1"
      p.info('abc-copyright').should == "(c) ASCAP"
      p.tunes[0].info('abc-copyright').should == nil
      p.propagate_tunebook_header
      p.tunes[0].info('abc-copyright').should == "(c) ASCAP"
    end

    it "recognizes info fields in the tune header" do
      p = parse "X:1\n%%abc-copyright (c) ASCAP\nA:Author"
      p.info('abc-copyright').should == nil
      p.tunes[0].info('abc-copyright').should == "(c) ASCAP"
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

  describe "M: (meter) field" do
    it "defaults to free meter" do
      p = parse "abc"
      p.tunes[0].meter.symbol.should == :free
    end
    it "can be explicitly defined as none" do
      p = parse "M:none\nabc"
      p.tunes[0].meter.symbol.should == :free
    end
    it "can be defined with numerator and denominator" do
      p = parse "M:6/8\nabc"
      p.tunes[0].meter.numerator.should == 6
      p.tunes[0].meter.denominator.should == 8
    end
    it "interprets common time" do
      p = parse "M:C\nabc"
      p.tunes[0].meter.numerator.should == 4
      p.tunes[0].meter.denominator.should == 4
      p.tunes[0].meter.symbol.should == :common
    end
    it "interprets cut time" do
      p = parse "M:C|\nabc"
      p.tunes[0].meter.numerator.should == 2
      p.tunes[0].meter.denominator.should == 4
      p.tunes[0].meter.symbol.should == :cut
    end
  end

  describe "L: (unit note length) field" do
    it "knows its value" do
      p = parse "L:1/4"
      p.tunes[0].unit_note_length.should == Rational(1, 4)
    end
    it "defaults to 1/8" do
      p = parse "abc"
      p.tunes[0].unit_note_length.should == Rational(1, 8)
    end
    it "accepts whole numbers" do
      p = parse "L:1\nabc"
      p.tunes[0].unit_note_length.should == 1
    end
  end

  describe "Q: (tempo) field" do
    it "can be of the simple form beat=bpm" do
      p = parse "X:1\nQ:1/4=120"
      p.tunes[0].tempo.beat_length.should == Rational(1, 4)
      p.tunes[0].tempo.beat_parts.should == [Rational(1, 4)]
      p.tunes[0].tempo.bpm.should == 120
    end

    it "can divide the beat into parts" do
      p = parse "X:1\nQ:1/4 3/8 1/4 3/8=40"
      p.tunes[0].tempo.beat_length.should == Rational(5, 4)
      p.tunes[0].tempo.beat_parts.should == 
        [Rational(1, 4), Rational(3, 8), Rational(1, 4), Rational(3, 8)]
      p.tunes[0].tempo.bpm.should == 40
    end

    it "can take a label at the front or the back" do
      p = parse "X:1\nQ:\"Allegro\" 1/4=120"
      p.tunes[0].tempo.label.should == "Allegro"
      p = parse "X:1\nQ:3/8=50 \"Slowly\""
      p.tunes[0].tempo.label.should == "Slowly"
      # TODO disallow label at front AND back
    end

    # TODO support Q:60
    it "can handle Q:60" do
      p = parse "X:1\nQ:60"
      p.tunes[0].tempo.bpm.should == 60
      p.tunes[0].tempo.beat_length.should == 1
      p.apply_note_lengths
      p.tunes[0].tempo.beat_length.should == Rational(1, 8)
    end

    # TODO support Q:C=120 ? but what does it mean?
    it "can handle Q:C=50" do
      p = parse "X:1\nQ:C=50"
      p.tunes[0].tempo.bpm.should == 50
      p.tunes[0].tempo.beat_length.should == Rational(1, 4)
    end
    
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
      p.tunes[0].items[0].note_length.should == 1
    end

    it "correctly reads a note length integer" do
      p = parse "a3"
      p.tunes[0].items[0].note_length.should == 3
    end

    it "correctly reads a note length fraction" do
      p = parse "a3/2"
      p.tunes[0].items[0].note_length.should == Rational(3,2)
    end

    it "correctly interprets note length slashes" do
      p = parse "a///"
      p.tunes[0].items[0].note_length.should == Rational(1, 8)
    end

    it "applies the default unit note length" do
      p = parse "ab2c3/2d3/e/"
      p.divvy_voices
      p.apply_note_lengths
      tune = p.tunes[0]
      tune.items[0].note_length.should == Rational(1, 8)
      tune.items[1].note_length.should == Rational(1, 4)
      tune.items[2].note_length.should == Rational(3, 16)
      tune.items[3].note_length.should == Rational(3, 16)
      tune.items[4].note_length.should == Rational(1, 16)
    end

    it "applies an explicit unit note length" do
      p = parse "L:1/2\nab2c3/2d3/e/"
      p.divvy_voices
      p.apply_note_lengths
      tune = p.tunes[0]
      tune.items[0].note_length.should == Rational(1, 2)
      tune.items[1].note_length.should == 1
      tune.items[2].note_length.should == Rational(3, 4)
      tune.items[3].note_length.should == Rational(3, 4)
      tune.items[4].note_length.should == Rational(1, 4)
    end

    it "can change unit note length with an inline L: field" do
      p = parse "L:1/2\na4[L:1/4]a4"
      p.divvy_voices
      p.apply_note_lengths
      tune = p.tunes[0]
      tune.items[0].note_length.should == 2
      tune.items[2].note_length.should == 1
    end

    it "can change unit note length with a standalone L: field" do
      p = parse "L:1/2\na4\nL:1/4\na4"
      p.divvy_voices
      p.apply_note_lengths
      tune = p.tunes[0]
      tune.items[0].note_length.should == 2
      tune.items[2].note_length.should == 1
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

    it "handles combinations of up octave and down octave" do
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
      p.tunes[0].items[0].pitch.accidental.should == 1
      p.tunes[0].items[1].pitch.accidental.should == 2
      p.tunes[0].items[2].pitch.accidental.should == -1
      p.tunes[0].items[3].pitch.accidental.should == -2
      p.tunes[0].items[4].pitch.accidental.should == 0
      p.tunes[0].items[5].pitch.accidental.should == nil
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
      p.tunes[0].divvy_voices
      p.tunes[0].apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == -2
    end

    it "retains accidentals within a measure when applying key signature" do
      p = parse "K:F\nB=BB"
      p.tunes[0].divvy_voices
      p.tunes[0].apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == -2
      p.tunes[0].items[1].pitch.height.should == -1
      p.tunes[0].items[2].pitch.height.should == -1
    end

    it "resets accidentals at end of measure" do
      p = parse "K:F\nB=B|B"
      p.tunes[0].divvy_voices
      p.tunes[0].apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == -2
      p.tunes[0].items[1].pitch.height.should == -1
      p.tunes[0].items[3].pitch.height.should == -2
    end

    it "does not reset accidentals at dotted bar line" do
      p = parse "K:F\nB=B.|B"
      p.tunes[0].divvy_voices
      p.tunes[0].apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == -2
      p.tunes[0].items[1].pitch.height.should == -1
      p.tunes[0].items[3].pitch.height.should == -1
    end

    it "can apply key signatures to all tunes in tunebook" do
      p = parse "K:Eb\nA=A^AA\n\nK:F\nB"
      p.divvy_voices
      p.apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == -4
      p.tunes[0].items[1].pitch.height.should == -3
      p.tunes[0].items[2].pitch.height.should == -2
      p.tunes[0].items[3].pitch.height.should == -2
      p.tunes[1].items[0].pitch.height.should == -2
    end

    it "does not apply key signature from previous tune" do
      p = parse "X:1\nK:Eb\nA\n\n\nX:2\nA"
      p.divvy_voices
      p.apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == -4
      p.tunes[1].items[0].pitch.height.should == -3
    end

    it "changes key signature when inline K: field found in tune body" do
      p = parse "X:1\nK:C\nC[K:A]C"
      p.divvy_voices
      p.apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == 0
      p.tunes[0].items[2].pitch.height.should == 1
    end

    it "changes key signature when standalone K: field found in tune body" do
      p = parse "X:1\nK:C\nC\nK:A\nC"
      p.divvy_voices
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
      p.tunes[0].items[0].note_length.should == Rational(3, 2)
      p.tunes[0].items[1].note_length.should == Rational(1, 4)
      p.tunes[0].items[2].note_length.should == 4
    end

    it "understands measure-count rests" do
      p = parse "Z4"
      p.tunes[0].items[0].measure_count.should == 4
    end

    it "knows the note length of measure-count rests after applying meter" do
      p = parse "M:C\nZ4[M:3/4]Z2\n"
      p.tunes[0].items[0].note_length.should == nil
      p.divvy_voices
      p.apply_meter
      p.tunes[0].items[0].note_length.should == 4
      p.tunes[0].items[2].note_length.should == Rational(6, 4)
    end

    it "applies the tunebook's meter to all tunes" do
      p = parse "M:C\n\nX:1\n\nX:2"
      p.meter.symbol.should == :common
      p.tunes[0].meter.symbol.should == :free
      p.tunes[1].meter.symbol.should == :free
      p.divvy_voices
      p.apply_meter
      p.tunes[0].meter.symbol.should == :common
      p.tunes[1].meter.symbol.should == :common
    end
    
    it "overrides the tunebook's meter with tune's meter" do
      p = parse "M:C\n\nX:1\nM:C|"
      p.meter.symbol.should == :common
      p.tunes[0].meter.symbol.should == :cut
      p.divvy_voices
      p.apply_meter
      p.tunes[0].meter.symbol.should == :cut
    end
  end

  describe "broken rhythm" do

    it "accepts broken rhythm markers" do
      parse "a>b c<d a>>b c2<<d2"
    end
    
    it "does not accept broken rhythm weirdness" do
      fail_to_parse "a<>b"
      fail_to_parse "a><b"
    end

    it "applies broken rhythm marker to following note" do
      p = parse "a>b"
      p.tunes[0].items[0].broken_rhythm_marker.should == nil
      p.tunes[0].items[1].broken_rhythm_marker.change('>').should == Rational(1, 2)
    end

    it "adjusts note lengths appropriately" do
      p = parse "a>b c<d e<<f g>>>a"
      tune = p.tunes[0]
      tune.items[0].note_length.should == 1
      tune.items[1].note_length.should == 1
      tune.items[2].note_length.should == 1
      tune.items[3].note_length.should == 1
      tune.items[4].note_length.should == 1
      tune.items[5].note_length.should == 1
      tune.items[6].note_length.should == 1
      tune.items[7].note_length.should == 1
      p.apply_broken_rhythms
      tune.items[0].note_length.should == Rational(3, 2)
      tune.items[1].note_length.should == Rational(1, 2)
      tune.items[2].note_length.should == Rational(1, 2)
      tune.items[3].note_length.should == Rational(3, 2)
      tune.items[4].note_length.should == Rational(1, 4)
      tune.items[5].note_length.should == Rational(7, 4)
      tune.items[6].note_length.should == Rational(15, 8)
      tune.items[7].note_length.should == Rational(1, 8)
    end
    
    it "works in tandem with unit note length and note length markers" do
      p = parse "L:1/8\na2>b2"
      p.divvy_voices
      p.apply_broken_rhythms
      p.apply_note_lengths
      p.tunes[0].items[0].note_length.should == Rational(3, 8)
      p.tunes[0].items[1].note_length.should == Rational(1, 8)
    end

  end
  
  describe "bar lines" do

    it "recognizes simple bar lines" do
      p = parse "a|b"
      bar = p.tunes[0].items[1]
      bar.is_a?(BarLine).should == true
      bar.type.should == :thin
    end

    it "recognizes double bar lines" do
      p = parse "a||b"
      p.tunes[0].items.count.should == 3
      bar = p.tunes[0].items[1]
      bar.is_a?(BarLine).should == true
      bar.type.should == :double
    end

    it "recognizes thin-thick bar lines" do
      p = parse "a|]"
      p.tunes[0].items.count.should == 2
      bar = p.tunes[0].items.last
      bar.is_a?(BarLine).should == true
      bar.type.should == :thin_thick
    end

    it "recognizes thick-thin bar lines" do
      p = parse "[|C"
      p.tunes[0].items.count.should == 2
      bar = p.tunes[0].items[0]
      bar.is_a?(BarLine).should == true
      bar.type.should == :thick_thin
    end

    it "recognizes dotted bar lines" do
      p = parse "a.|b"
      p.tunes[0].items.count.should == 3
      bar = p.tunes[0].items[1]
      bar.is_a?(BarLine).should == true
      bar.type.should == :dotted
    end

    it "recognizes invisible bar lines" do
      p = parse "a[|]b"
      p.tunes[0].items.count.should == 3
      bar = p.tunes[0].items[1]
      bar.is_a?(BarLine).should == true
      bar.type.should == :invisible
    end

    it "knows the left repeat sign" do
      p = parse "|:"
      p.tunes[0].items[0].type.should == :thin
      p.tunes[0].items[0].repeat_before.should == 0
      p.tunes[0].items[0].repeat_after.should == 1
    end

    it "knows the right repeat sign" do
      p = parse ":|"
      p.tunes[0].items[0].type.should == :thin
      p.tunes[0].items[0].repeat_before.should == 1
      p.tunes[0].items[0].repeat_after.should == 0
    end
    
    it "can handle repeats on thin-thick bars" do
      p = parse ":|]"
      p.tunes[0].items[0].type.should == :thin_thick
      p.tunes[0].items[0].repeat_before.should == 1
      p.tunes[0].items[0].repeat_after.should == 0
    end

    it "can handle repeats on thick-thin bars" do
      p = parse "[|:"
      p.tunes[0].items[0].type.should == :thick_thin
      p.tunes[0].items[0].repeat_before.should == 0
      p.tunes[0].items[0].repeat_after.should == 1
    end

    it "can handle multiple repeats" do
      p = parse "::|"
      p.tunes[0].items[0].repeat_before.should == 2
      p.tunes[0].items[0].repeat_after.should == 0
    end
  end

  describe "variant endings" do
    it "can parse first and second repeats" do
      p = parse "[1 abc :|[2 def ||"
      p = parse "abc|1 abc:|2 def ||"
      p.tunes[0].items[3].variant_number.should == 1
      p.tunes[0].items[7].variant_number.should == 2
    end
    it "can parse complex variants" do
      p = parse "[1,3,5-7 abc || [2,4,8 def ||"
    end
  end

  describe "ties" do
    it "accepts ties" do
      p = parse "a-a"
      p.tunes[0].items[1].is_a?(Tie).should == true
    end
    it "accepts ties that are really slurs" do
      p = parse "a-b"
      p.tunes[0].items[1].is_a?(Tie).should == true
    end
  end

  describe "slurs" do
    it "accepts slurs" do
      p = parse "d(ab^c)d"
      p.tunes[0].items[1].is_a?(Slur).should == true
      p.tunes[0].items[1].start_slur.should == true
      p.tunes[0].items[5].end_slur.should == true
    end
    it "can nest slurs" do
      p = parse "d(a(b^c)d)"
      p.tunes[0].items[1].start_slur.should == true
      p.tunes[0].items[3].start_slur.should == true
      p.tunes[0].items[6].end_slur.should == true
      p.tunes[0].items[8].end_slur.should == true
    end
  end

  describe "gracenotes" do
    it "parses gracenotes" do
      p = parse "{gege}B"
      p = parse "{/ge4d}B"
    end
    
    it "allows broken rhythm symbols inside gracenotes" do
      p = parse "{a>b}A"
    end

    it "allows broken rhythm symbols before gracenote" do
      p = parse "B>{ab}A"
    end

    # TODO make this work
    #it "allows broken rhythm symbols after gracenote" do
    #  p = parse "B{ab}>A"
    #end

  end

  describe "tuplets" do
    it "parses simple tuplets" do
      p = parse "(2 ab"
      p.tunes[0].items[0].is_a?(ABC::TupletMarker).should == true
      p.tunes[0].items[0].ratio.should == Rational(3, 2)
      p.tunes[0].items[0].num_notes.should == 2
      p.tunes[0].items[0].compound_meter = true
      p.tunes[0].items[0].ratio.should == Rational(3, 2)
      
      p = parse "(3 abc"
      p.tunes[0].items[0].ratio.should == Rational(2, 3)
      p.tunes[0].items[0].num_notes.should == 3
      p.tunes[0].items[0].compound_meter = true
      p.tunes[0].items[0].ratio.should == Rational(2, 3)

      p = parse "(4 abcd"
      p.tunes[0].items[0].ratio.should == Rational(3, 4)
      p.tunes[0].items[0].num_notes.should == 4
      p.tunes[0].items[0].compound_meter = true
      p.tunes[0].items[0].ratio.should == Rational(3, 4)

      p = parse "(5 abcde"
      p.tunes[0].items[0].ratio.should == Rational(2, 5)
      p.tunes[0].items[0].num_notes.should == 5
      p.tunes[0].items[0].compound_meter = true
      p.tunes[0].items[0].ratio.should == Rational(3, 5)

      p = parse "(6 abc abc"
      p.tunes[0].items[0].ratio.should == Rational(2, 6)
      p.tunes[0].items[0].num_notes.should == 6
      p.tunes[0].items[0].compound_meter = true
      p.tunes[0].items[0].ratio.should == Rational(2, 6)

      p = parse "(7 abcd abc"
      p.tunes[0].items[0].ratio.should == Rational(2, 7)
      p.tunes[0].items[0].num_notes.should == 7
      p.tunes[0].items[0].compound_meter = true
      p.tunes[0].items[0].ratio.should == Rational(3, 7)

      p = parse "(8 abcd abcd"
      p.tunes[0].items[0].ratio.should == Rational(3, 8)
      p.tunes[0].items[0].num_notes.should == 8
      p.tunes[0].items[0].compound_meter = true
      p.tunes[0].items[0].ratio.should == Rational(3, 8)

      p = parse "(9 abc abc abc"
      p.tunes[0].items[0].ratio.should == Rational(2, 9)
      p.tunes[0].items[0].num_notes.should == 9
      p.tunes[0].items[0].compound_meter = true
      p.tunes[0].items[0].ratio.should == Rational(3, 9)

    end

    it "parses complex tuplets" do
      p = parse "(3:4:6 abc abc"
      p.tunes[0].items[0].ratio.should == Rational(4, 3)
      p.tunes[0].items[0].num_notes.should == 6
    end

    it "parses complex tuplets with third element missing" do
      p = parse "(3:4 abc"
      p.tunes[0].items[0].ratio.should == Rational(4, 3)
      p.tunes[0].items[0].num_notes.should == 3
      p = parse "(3:4: abc"
      p.tunes[0].items[0].ratio.should == Rational(4, 3)
      p.tunes[0].items[0].num_notes.should == 3
    end

    it "parses complex tuplets with second element missing" do
      p = parse "(5::10 abcde abcde"
      p.tunes[0].items[0].ratio.should == Rational(2, 5)
      p.tunes[0].items[0].num_notes.should == 10
      p.tunes[0].items[0].compound_meter = true
      p.tunes[0].items[0].ratio.should == Rational(3, 5)
    end

    it "parses complex tuplets with second and third elements missing" do
      p = parse "(7:: abcd abc"
      p.tunes[0].items[0].ratio.should == Rational(2, 7)
      p.tunes[0].items[0].num_notes.should == 7
      p.tunes[0].items[0].compound_meter = true
      p.tunes[0].items[0].ratio.should == Rational(3, 7)
      p = parse "(7: abcd abc" # also works with only one :
      p.tunes[0].items[0].ratio.should == Rational(2, 7)
      p.tunes[0].items[0].num_notes.should == 7
      p.tunes[0].items[0].compound_meter = true
      p.tunes[0].items[0].ratio.should == Rational(3, 7)
    end

  end

  describe "decorations" do
    it "recognizes +symbol+ decorations" do
      p = parse "+trill+ A"
      p.tunes[0].items[0].decorations[0].should == "trill";
    end
    it "recognizes shortcut decorations" do
      p = parse ".A~BuC"
      p.tunes[0].items[0].decorations[0].should == "staccato";
      p.tunes[0].items[1].decorations[0].should == "roll";
      p.tunes[0].items[2].decorations[0].should == "upbow";
    end

  end

  describe "chords" do
    it "recognizes chords" do
      p = parse "[CEG]"
      p.tunes[0].items[0].stroke.is_a?(Chord).should == true
      p.tunes[0].items[0].notes.count.should == 3
      p.tunes[0].items[0].notes[0].is_a?(Note).should == true
      p.tunes[0].items[0].notes[0].pitch.height.should == 0
    end
    it "allows length modifier on chords" do
      p = parse "[CEG]3/2"
      p.tunes[0].items[0].note_length.should == Rational(3, 2)
    end
    it "allows length modifiers inside chords" do
      p = parse "[C2E2G2]"
      p.tunes[0].items[0].notes[0].note_length.should == 2
    end
    it "multiplies inner length modifiers by outer" do
      p = parse "[C2E2G2]3/"
      p.tunes[0].items[0].notes[0].note_length.should == 2
      p.apply_chord_lengths
      p.tunes[0].items[0].notes[0].note_length.should == 3
    end
    it "applies key signatures to chord pitches" do
      p = parse "K:D\n[DFA]"
      p.tunes[0].items[0].notes[1].pitch.height.should == 5
      p.divvy_voices
      p.apply_key_signatures
      p.tunes[0].items[0].notes[1].pitch.height.should == 6      
    end
    it "applies measure accidentals to chord pitches" do
      p = parse "^F[DFA]|[DFA]"
      p.tunes[0].items[1].notes[1].pitch.height.should == 5
      p.divvy_voices
      p.apply_key_signatures
      p.tunes[0].items[1].notes[1].pitch.height.should == 6      
      p.tunes[0].items[3].notes[1].pitch.height.should == 5      
    end
    it "creates measure accidentals from chord pitches" do
      p = parse "[D^FA]F|F"
      p.tunes[0].items[1].pitch.height.should == 5
      p.divvy_voices
      p.apply_key_signatures
      p.tunes[0].items[1].pitch.height.should == 6      
      p.tunes[0].items[3].pitch.height.should == 5
    end
  end

  describe "chord symbols" do
    it "can attach a chord symbol to a note" do
      p = parse '"Am7"A2D2'
      p.tunes[0].items[0].chord_symbol.should == "Am7"
    end
    it "can handle bass notes" do
      p = parse '"C/E"G'
      p.tunes[0].items[0].chord_symbol.should == "C/E"
    end
    it "can handle alternate chords" do
      p = parse '"G(Em/G)"G'
      p.tunes[0].items[0].chord_symbol.should == "G(Em/G)"
    end
    # TODO parse the chord symbols for note, type, bassnote etc
  end

  describe "annotations" do
    it "can place text above a note" do
      p = parse '"^above"c'
      p.tunes[0].items[0].annotations[0].placement.should == :above
      p.tunes[0].items[0].annotations[0].text.should == "above"
    end
    it "can place text below a note" do
      p = parse '"_below"c'
      p.tunes[0].items[0].annotations[0].placement.should == :below
      p.tunes[0].items[0].annotations[0].text.should == "below"
    end
    it "can place text to the left and right of a note" do
      p = parse '"<(" ">)" c'
      p.tunes[0].items[0].annotations[0].placement.should == :left
      p.tunes[0].items[0].annotations[0].text.should == "("
      p.tunes[0].items[0].annotations[1].placement.should == :right
      p.tunes[0].items[0].annotations[1].text.should == ")"
    end
    it "can handle annotations with unspecified placement" do
      p = parse '"@wherever" c'
      p.tunes[0].items[0].annotations[0].placement.should == :unspecified
      p.tunes[0].items[0].annotations[0].text.should == "wherever"
    end
  end

  it "accepts spacers" do
    parse "ab y de"
  end
  
  describe "beaming support" do
    it "beams adjacent notes" do
      p = parse "abc d e"
      p.apply_beams
      p.tunes[0].items[0].beam.should == :start
      p.tunes[0].items[1].beam.should == :middle
      p.tunes[0].items[2].beam.should == :end
      p.tunes[0].items[3].beam.should == nil
      p.tunes[0].items[4].beam.should == nil
    end
    it "can stretch beam with backticks" do
      p = parse "a``b c3/`^d"
      p.apply_beams
      p.tunes[0].items[0].beam.should == :start
      p.tunes[0].items[1].beam.should == :end
      p.tunes[0].items[2].beam.should == :start
      p.tunes[0].items[3].beam.should == :end
    end
  end

  describe "lyrics support" do
    it "pares whole word lyrics" do
      p = parse "gcea\nw:my dog has fleas"
      # items[4] is the lyrics field
      p.tunes[0].items[4].units.count.should == 4
      p.tunes[0].items[4].units[0].text.should == "my"
      p.tunes[0].items[4].units[1].text.should == "dog"
      p.tunes[0].items[4].units[2].text.should == "has"
      p.tunes[0].items[4].units[3].text.should == "fleas"
    end
  end

end
