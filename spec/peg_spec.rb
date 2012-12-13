$LOAD_PATH.unshift File.expand_path('../lib')
require 'abc/parser'

describe "abc-2.1 PEG" do

  before do
    @parser = ABCParser.new
  end


  # HELPERS

  def parse(abc, options = {:root => :abc_file})
    p = @parser.parse abc, options
    p.should_not be(nil), @parser.failure_reason
    p
  end
  
  def fail_to_parse(abc, options={:root => :abc_file})
    p = @parser.parse abc, options
    p.should == nil
    p
  end

  def parse_fragment(abc)
    parse abc, :root => :abc_fragment
  end
  
  def fail_to_parse_fragment(abc)
    fail_to_parse abc, :root => :abc_fragment
  end
  
  def tune1
    "X:1\nT:T1\nK:C"
  end

  def tune2
    "X:2\nT:T2\nK:D"
  end

  # TESTS

  describe "header basics" do

    it "accepts a file header field" do
      p = parse "C:Beethoven\n\nX:1\nT:T\nK:C"
      p.header.fields.count.should == 1
      p.header.fields[0].text_value.should == "C:Beethoven"
    end
    
    it "separates fields" do
      p = parse "X:1\nT:Love Me Do\nK:C"
      p.tunes[0].header.fields[0].text_value.should == "X:1"
      p.tunes[0].header.fields[1].text_value.should == "T:Love Me Do"
    end
    
    it "differentiates file header from tune header" do
      p = parse "H:File\n\nX:1\nT:Tune\nK:C"
      p.header.should_not == nil
      p.tunes.count.should == 1
      p.tunes[0].header.should_not == nil
    end
    
    it "supports inline fields in the tune body" do
      p = parse_fragment "X:1\nK:C\nabc[K:A]abc"
    end

    it "accepts no tune header fields after the K: field" do
      fail_to_parse "K:C\nA:Author\nabc"
    end

    it "can handle a standalone body field right after the K: field" do
      p = parse_fragment "K:C\nK:F\nabc"
      p.key.tonic.should == "C"
      p.items[0].value.tonic.should == "F"
    end

  end


  it "supports multiple tunes" do
    p = parse "#{tune1}\n\n#{tune2}"
    p.tunes.count.should == 2
  end

  it "supports multiple tunes with music" do
    p = parse "X:1\nT:T\nK:C\nABC\n\nX:2\nT:T2\nK:E\nDEF"
    p.tunes.count.should == 2
  end

  it "allows mulitple blank lines between tunes" do
    p = parse "#{tune1}\n\n\n\n#{tune2}"
    p.tunes.count.should == 2
  end


  describe "fields" do
    it "knows the refnum field" do
      p = parse "X:2\nT:T2\nK:C\nabc\n\nX:37\nT:T37\nK:D\nABC"
      p.tunes[0].refnum.should == 2
      p.tunes[1].refnum.should == 37
      p.tune(2).should == p.tunes[0]
      p.tune(37).should == p.tunes[1]
    end
    it "defaults refnum to 1" do
      p = parse_fragment "ABC"
      p.refnum.should == 1
    end

    it "knows the string fields" do
      %w{Bbook Ccomposer Ddisc Furl Ggroup Hhistory Nnotations Oorigin 
         Rrhythm rremark Ssource Ztranscription}.each do |field|
        label = field[0]
        name = field[1..-1]
        p = parse "#{label}:File Header\n\nX:1\nT:T1\nK:C\n\nX:2\nT:T2\n#{label}:Tune Header\n#{label}:again\nK:D"
        p.propagate_tunebook_header
        p.send(name).should == "File Header"
        p.tunes[0].send(name).should == "File Header"
        p.tunes[1].send(name).should == ["Tune Header", "again"]
      end
    end

    it "allows meter fields in the file header" do
      p = parse "M:3/4\n\nX:1\nT:T\nK:C"
      p.meter.measure_length.should == Rational(3, 4)
    end

  end

  describe "key" do
    it "parses the tonic" do
      p = parse_fragment "K:Ebminor=e^c"
      p.key.tonic.should == "Eb"
    end
    it "parses the mode" do
      p = parse_fragment "K:Ebminor=e^c"
      p.key.mode.should == "minor"
      p = parse_fragment "K:A Mixolydian"
      p.key.mode.should == "mixolydian"
    end
    it "parses the extra accidentals" do
      p = parse_fragment "K:Ebminor=e^c"
      p.key.extra_accidentals.should include 'E' => 0, 'C' => 1
    end

    it "delivers accidentals for major key" do
      p = parse_fragment "K:Eb"
      sig = p.key.signature
      sig.should include 'A' => -1, 'B' => -1, 'E' => -1
      sig.should_not include 'C', 'D', 'F', 'G'
    end

    it "delivers accidentals for key with mode" do
      p = parse_fragment "K:A# Phr"
      sig = p.key.signature
      sig.should include 'C' => 1, 'D' => 1, 'E' => 1, 'F' => 1, 'G' => 1, 'A' => 1
      sig.should_not include 'B'
    end

    it "delivers accidentals for key with extra accidentals" do
      p = parse_fragment "K:F =b ^C"
      sig = p.key.signature
      sig.should include 'C' => 1
      sig.should_not include %w{D E F G A B}
    end

    it "allows K:none" do
      p = parse_fragment "K:none"
      p.key.tonic.should == nil
      p.key.mode.should == nil
      p.key.signature.should == {}
    end

  end

  # TODO pending
  # describe "extended info fields" do

  #   # it "recognizes an info field in the title header" do
  #   #   p = parse_fragment "%%abc-copyright (c) ASCAP\n\nX:1"
  #   #   p.info('abc-copyright').should == "(c) ASCAP"
  #   #   p.info('abc-copyright').should == nil
  #   #   p.propagate_tunebook_header
  #   #   p.info('abc-copyright').should == "(c) ASCAP"
  #   # end

  #   it "recognizes info fields in the tune header" do
  #     p = parse_fragment "X:1\n%%abc-copyright (c) ASCAP\nA:Author"
  #     p.info('abc-copyright').should == nil
  #     p.info('abc-copyright').should == "(c) ASCAP"
  #   end
    
  #   it "does not recognize info fields in the tune body" do
  #     fail_to_parse_fragment "X:1\n abc\n%%abc-copyright (c) ASCAP\ndef"
  #   end

  # end

  it "recognizes music" do
    parse_fragment "X:1\n abc"
  end

  it "accepts raw music with no headers" do
    parse_fragment "abc"
  end

  describe "M: (meter) field" do
    it "defaults to free meter" do
      p = parse_fragment "abc"
      p.meter.symbol.should == :free
    end
    it "can be explicitly defined as none" do
      p = parse_fragment "M:none\nabc"
      p.meter.symbol.should == :free
    end
    it "can be defined with numerator and denominator" do
      p = parse_fragment "M:6/8\nabc"
      p.meter.numerator.should == 6
      p.meter.denominator.should == 8
    end
    it "interprets common time" do
      p = parse_fragment "M:C\nabc"
      p.meter.numerator.should == 4
      p.meter.denominator.should == 4
      p.meter.symbol.should == :common
    end
    it "interprets cut time" do
      p = parse_fragment "M:C|\nabc"
      p.meter.numerator.should == 2
      p.meter.denominator.should == 4
      p.meter.symbol.should == :cut
    end
  end

  describe "L: (unit note length) field" do
    it "knows its value" do
      p = parse_fragment "L:1/4"
      p.unit_note_length.should == Rational(1, 4)
    end
    it "defaults to 1/8" do
      p = parse_fragment "abc"
      p.unit_note_length.should == Rational(1, 8)
    end
    it "accepts whole numbers" do
      p = parse_fragment "L:1\nabc"
      p.unit_note_length.should == 1
    end
  end

  describe "Q: (tempo) field" do
    it "can be of the simple form beat=bpm" do
      p = parse_fragment "X:1\nQ:1/4=120"
      p.tempo.beat_length.should == Rational(1, 4)
      p.tempo.beat_parts.should == [Rational(1, 4)]
      p.tempo.bpm.should == 120
    end

    it "can divide the beat into parts" do
      p = parse_fragment "X:1\nQ:1/4 3/8 1/4 3/8=40"
      p.tempo.beat_length.should == Rational(5, 4)
      p.tempo.beat_parts.should == 
        [Rational(1, 4), Rational(3, 8), Rational(1, 4), Rational(3, 8)]
      p.tempo.bpm.should == 40
    end

    it "can take a label at the front or the back" do
      p = parse_fragment "X:1\nQ:\"Allegro\" 1/4=120"
      p.tempo.label.should == "Allegro"
      p = parse_fragment "X:1\nQ:3/8=50 \"Slowly\""
      p.tempo.label.should == "Slowly"
      # TODO disallow label at front AND back
    end

    # TODO support Q:60
    it "can handle Q:60" do
      p = parse_fragment "X:1\nQ:60"
      p.tempo.bpm.should == 60
      p.tempo.beat_length.should == 1
      p.apply_note_lengths
      p.tempo.beat_length.should == Rational(1, 8)
    end

    # TODO support Q:C=120 ? but what does it mean?
    it "can handle Q:C=50" do
      p = parse_fragment "X:1\nQ:C=50"
      p.tempo.bpm.should == 50
      p.tempo.beat_length.should == Rational(1, 4)
    end
    
  end
  
  describe "note lengths" do
    it "accepts short and long notes" do
      parse_fragment "a2 b3/2 c3/ d/ d/2e//"
    end

    it "does not accept weirdo note lengths" do
      fail_to_parse_fragment "a//4"
      fail_to_parse_fragment "a3//4"
    end

    it "uses multiplier of 1 for empty note length" do
      p = parse_fragment "a"
      p.items[0].note_length.should == 1
    end

    it "correctly reads a note length integer" do
      p = parse_fragment "a3"
      p.items[0].note_length.should == 3
    end

    it "correctly reads a note length fraction" do
      p = parse_fragment "a3/2"
      p.items[0].note_length.should == Rational(3,2)
    end

    it "correctly interprets note length slashes" do
      p = parse_fragment "a///"
      p.items[0].note_length.should == Rational(1, 8)
    end

    it "applies the default unit note length" do
      p = parse_fragment "ab2c3/2d3/e/"
      p.divvy_voices
      p.apply_note_lengths
      tune = p
      tune.items[0].note_length.should == Rational(1, 8)
      tune.items[1].note_length.should == Rational(1, 4)
      tune.items[2].note_length.should == Rational(3, 16)
      tune.items[3].note_length.should == Rational(3, 16)
      tune.items[4].note_length.should == Rational(1, 16)
    end

    it "applies an explicit unit note length" do
      p = parse_fragment "L:1/2\nab2c3/2d3/e/"
      p.divvy_voices
      p.apply_note_lengths
      tune = p
      tune.items[0].note_length.should == Rational(1, 2)
      tune.items[1].note_length.should == 1
      tune.items[2].note_length.should == Rational(3, 4)
      tune.items[3].note_length.should == Rational(3, 4)
      tune.items[4].note_length.should == Rational(1, 4)
    end

    it "can change unit note length with an inline L: field" do
      p = parse_fragment "L:1/2\na4[L:1/4]a4"
      p.divvy_voices
      p.apply_note_lengths
      tune = p
      tune.items[0].note_length.should == 2
      tune.items[2].note_length.should == 1
    end

    it "can change unit note length with a standalone L: field" do
      p = parse_fragment "L:1/2\na4\nL:1/4\na4"
      p.divvy_voices
      p.apply_note_lengths
      tune = p
      tune.items[0].note_length.should == 2
      tune.items[2].note_length.should == 1
    end

  end

  describe "octave" do

    it "accepts notes in various octaves" do
      parse_fragment "ABC abc a,b'C,,D'' e,', f'', G,,,,,'''"
    end

    it "correctly calculates the octave for note letters" do
      p = parse_fragment "CcAg"
      p.items[0].pitch.octave.should == 0
      p.items[1].pitch.octave.should == 1
      p.items[2].pitch.octave.should == 0
      p.items[3].pitch.octave.should == 1
    end
    
    it "shifts the octave up with apostrophes" do
      p = parse_fragment "C'c''"
      p.items[0].pitch.octave.should == 1
      p.items[1].pitch.octave.should == 3
    end

    it "shifts the octave down with commas" do
      p = parse_fragment "C,,,,c,,"
      p.items[0].pitch.octave.should == -4
      p.items[1].pitch.octave.should == -1
    end

    it "handles combinations of up octave and down octave" do
      p = parse_fragment "C,',',,c,,'''',"
      p.items[0].pitch.octave.should == -2
      p.items[1].pitch.octave.should == 2
    end

  end

  describe "accidentals" do
    
    it "accepts notes with accidentals" do
      parse_fragment "^A ^^a2 _b/ __C =D"
    end

    it "does not accept bizarro accidentals" do
      fail_to_parse_fragment "^_A"
      fail_to_parse_fragment "_^A"
      fail_to_parse_fragment "^^^A"
      fail_to_parse_fragment "=^A"
      fail_to_parse_fragment "___A"
      fail_to_parse_fragment "=_A"
    end

    it "values sharps and flats accurately" do
      p = parse_fragment "^A^^a2_b/__C=DF"
      p.items[0].pitch.accidental.should == 1
      p.items[1].pitch.accidental.should == 2
      p.items[2].pitch.accidental.should == -1
      p.items[3].pitch.accidental.should == -2
      p.items[4].pitch.accidental.should == 0
      p.items[5].pitch.accidental.should == nil
    end
  end

  describe "pitch" do
    it "knows note name" do
      p = parse_fragment "C^Cd_e''F,',^^E'g'''__Ba,,,,b"
      p.items[0].pitch.note.should == 'C'
      p.items[1].pitch.note.should == 'C'
      p.items[2].pitch.note.should == 'D'
      p.items[3].pitch.note.should == 'E'
      p.items[4].pitch.note.should == 'F'
      p.items[5].pitch.note.should == 'E'
      p.items[6].pitch.note.should == 'G'
      p.items[7].pitch.note.should == 'B'
      p.items[8].pitch.note.should == 'A'
      p.items[9].pitch.note.should == 'B'
    end
    it "knows height in octave" do
      p = parse_fragment "C^^B,d_e''EF,',^^E'g'''_a__B,,,,^ab"
      0.upto 11 do |i|
        p.items[i].pitch.height_in_octave.should == i
      end
    end
    it "knows height" do
      p = parse_fragment "C^^B,d_e''EF,',"
      p.items[0].pitch.height.should == 0
      p.items[1].pitch.height.should == 1
      p.items[2].pitch.height.should == 14
      p.items[3].pitch.height.should == 39
      p.items[4].pitch.height.should == 4
      p.items[5].pitch.height.should == -7
    end

    it "knows height given a key signature" do
      p = parse_fragment "CD=DEF^FG_G"
      key = { 'C'=>1, 'D'=>1, 'F'=>1, 'G'=>1 } # E maj
      p.items[0].pitch.height(key).should == 1
      p.items[1].pitch.height(key).should == 3
      p.items[2].pitch.height(key).should == 2
      p.items[3].pitch.height(key).should == 4
      p.items[4].pitch.height(key).should == 6
      p.items[5].pitch.height(key).should == 6
      p.items[6].pitch.height(key).should == 8
      p.items[7].pitch.height(key).should == 6
      p = parse_fragment "AB=BCD^DE_E"
      key = { 'A'=>-1, 'B'=>-1, 'D'=>-1, 'E'=>-1 } # Ab maj
      p.items[0].pitch.height(key).should == 8
      p.items[1].pitch.height(key).should == 10
      p.items[2].pitch.height(key).should == 11
      p.items[3].pitch.height(key).should == 0
      p.items[4].pitch.height(key).should == 1
      p.items[5].pitch.height(key).should == 3
      p.items[6].pitch.height(key).should == 3
      p.items[7].pitch.height(key).should == 3
    end

  end

  describe "key signatures" do

    it "can apply the tune's key signature to a tune" do
      p = parse_fragment "K:F\nB"
      p.items[0].pitch.height.should == 11
      p.divvy_voices
      p.apply_key_signatures
      p.items[0].pitch.height.should == 10
    end

    it "retains accidentals within a measure when applying key signature" do
      p = parse_fragment "K:F\nB=BB"
      p.divvy_voices
      p.apply_key_signatures
      p.items[0].pitch.height.should == 10
      p.items[1].pitch.height.should == 11
      p.items[2].pitch.height.should == 11
    end

    it "resets accidentals at end of measure" do
      p = parse_fragment "K:F\nB=B|B"
      p.divvy_voices
      p.apply_key_signatures
      p.items[0].pitch.height.should == 10
      p.items[1].pitch.height.should == 11
      p.items[3].pitch.height.should == 10
    end

    it "does not reset accidentals at dotted bar line" do
      p = parse_fragment "K:F\nB=B.|B"
      p.divvy_voices
      p.apply_key_signatures
      p.items[0].pitch.height.should == 10
      p.items[1].pitch.height.should == 11
      p.items[3].pitch.height.should == 11
    end

    it "can apply key signatures to all tunes in tunebook" do
      p = parse "X:1\nT:T\nK:Eb\nA=A^AA\n\nX:2\nT:T2\nK:F\nB"
      p.divvy_voices
      p.apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == 8
      p.tunes[0].items[1].pitch.height.should == 9
      p.tunes[0].items[2].pitch.height.should == 10
      p.tunes[0].items[3].pitch.height.should == 10
      p.tunes[1].items[0].pitch.height.should == 10
    end

    it "does not apply key signature from previous tune" do
      p = parse "X:1\nT:T\nK:Eb\nA\n\n\nX:2\nT:T2\nK:C\nA"
      p.divvy_voices
      p.apply_key_signatures
      p.tunes[0].items[0].pitch.height.should == 8
      p.tunes[1].items[0].pitch.height.should == 9
    end

    it "changes key signature when inline K: field found in tune body" do
      p = parse_fragment "X:1\nK:C\nC[K:A]C"
      p.divvy_voices
      p.apply_key_signatures
      p.items[0].pitch.height.should == 0
      p.items[2].pitch.height.should == 1
    end

    it "changes key signature when standalone K: field found in tune body" do
      p = parse_fragment "X:1\nK:C\nC\nK:A\nC"
      p.divvy_voices
      p.apply_key_signatures
      p.items[0].pitch.height.should == 0
      p.items[2].pitch.height.should == 1
    end

  end



  describe "gracenotes" do
    it "parses gracenotes" do
      p = parse_fragment "{gege}B"
      p = parse_fragment "{/ge4d}B"
    end
    
    it "allows broken rhythm symbols inside gracenotes" do
      p = parse_fragment "{a>b}A"
    end

    it "allows broken rhythm symbols before gracenote" do
      p = parse_fragment "B>{ab}A"
    end

    # TODO make this work
    #it "allows broken rhythm symbols after gracenote" do
    #  p = parse_fragment "B{ab}>A"
    #end

  end

  describe "tuplets" do
    it "parses simple tuplets" do
      p = parse_fragment "(2 ab"
      p.items[0].is_a?(ABC::TupletMarker).should == true
      p.items[0].ratio.should == Rational(3, 2)
      p.items[0].num_notes.should == 2
      p.items[0].compound_meter = true
      p.items[0].ratio.should == Rational(3, 2)
      
      p = parse_fragment "(3 abc"
      p.items[0].ratio.should == Rational(2, 3)
      p.items[0].num_notes.should == 3
      p.items[0].compound_meter = true
      p.items[0].ratio.should == Rational(2, 3)

      p = parse_fragment "(4 abcd"
      p.items[0].ratio.should == Rational(3, 4)
      p.items[0].num_notes.should == 4
      p.items[0].compound_meter = true
      p.items[0].ratio.should == Rational(3, 4)

      p = parse_fragment "(5 abcde"
      p.items[0].ratio.should == Rational(2, 5)
      p.items[0].num_notes.should == 5
      p.items[0].compound_meter = true
      p.items[0].ratio.should == Rational(3, 5)

      p = parse_fragment "(6 abc abc"
      p.items[0].ratio.should == Rational(2, 6)
      p.items[0].num_notes.should == 6
      p.items[0].compound_meter = true
      p.items[0].ratio.should == Rational(2, 6)

      p = parse_fragment "(7 abcd abc"
      p.items[0].ratio.should == Rational(2, 7)
      p.items[0].num_notes.should == 7
      p.items[0].compound_meter = true
      p.items[0].ratio.should == Rational(3, 7)

      p = parse_fragment "(8 abcd abcd"
      p.items[0].ratio.should == Rational(3, 8)
      p.items[0].num_notes.should == 8
      p.items[0].compound_meter = true
      p.items[0].ratio.should == Rational(3, 8)

      p = parse_fragment "(9 abc abc abc"
      p.items[0].ratio.should == Rational(2, 9)
      p.items[0].num_notes.should == 9
      p.items[0].compound_meter = true
      p.items[0].ratio.should == Rational(3, 9)

    end

    it "parses complex tuplets" do
      p = parse_fragment "(3:4:6 abc abc"
      p.items[0].ratio.should == Rational(4, 3)
      p.items[0].num_notes.should == 6
    end

    it "parses complex tuplets with third element missing" do
      p = parse_fragment "(3:4 abc"
      p.items[0].ratio.should == Rational(4, 3)
      p.items[0].num_notes.should == 3
      p = parse_fragment "(3:4: abc"
      p.items[0].ratio.should == Rational(4, 3)
      p.items[0].num_notes.should == 3
    end

    it "parses complex tuplets with second element missing" do
      p = parse_fragment "(5::10 abcde abcde"
      p.items[0].ratio.should == Rational(2, 5)
      p.items[0].num_notes.should == 10
      p.items[0].compound_meter = true
      p.items[0].ratio.should == Rational(3, 5)
    end

    it "parses complex tuplets with second and third elements missing" do
      p = parse_fragment "(7:: abcd abc"
      p.items[0].ratio.should == Rational(2, 7)
      p.items[0].num_notes.should == 7
      p.items[0].compound_meter = true
      p.items[0].ratio.should == Rational(3, 7)
      p = parse_fragment "(7: abcd abc" # also works with only one :
      p.items[0].ratio.should == Rational(2, 7)
      p.items[0].num_notes.should == 7
      p.items[0].compound_meter = true
      p.items[0].ratio.should == Rational(3, 7)
    end

  end

  describe "decorations" do
    it "recognizes +symbol+ decorations" do
      p = parse_fragment "+trill+ A"
      p.items[0].decorations[0].should == "trill";
    end
    it "recognizes shortcut decorations" do
      p = parse_fragment ".A~BuC"
      p.items[0].decorations[0].should == "staccato";
      p.items[1].decorations[0].should == "roll";
      p.items[2].decorations[0].should == "upbow";
    end

  end

  describe "chords" do
    it "recognizes chords" do
      p = parse_fragment "[CEG]"
      p.items[0].is_a?(Chord).should == true
      p.items[0].notes.count.should == 3
      p.items[0].notes[0].is_a?(Note).should == true
      p.items[0].notes[0].pitch.height.should == 0
    end
    it "allows length modifier on chords" do
      p = parse_fragment "[CEG]3/2"
      p.items[0].note_length.should == Rational(3, 2)
    end
    it "allows length modifiers inside chords" do
      p = parse_fragment "[C2E2G2]"
      p.items[0].notes[0].note_length.should == 2
    end
    it "multiplies inner length modifiers by outer" do
      p = parse_fragment "[C2E2G2]3/"
      p.items[0].notes[0].note_length.should == 3
    end
    it "applies key signatures to chord pitches" do
      p = parse_fragment "K:D\n[DFA]"
      p.items[0].notes[1].pitch.height.should == 5
      p.divvy_voices
      p.apply_key_signatures
      p.items[0].notes[1].pitch.height.should == 6      
    end
    it "applies measure accidentals to chord pitches" do
      p = parse_fragment "^F[DFA]|[DFA]"
      p.items[1].notes[1].pitch.height.should == 5
      p.divvy_voices
      p.apply_key_signatures
      p.items[1].notes[1].pitch.height.should == 6      
      p.items[3].notes[1].pitch.height.should == 5      
    end
    it "creates measure accidentals from chord pitches" do
      p = parse_fragment "[D^FA]F|F"
      p.items[1].pitch.height.should == 5
      p.divvy_voices
      p.apply_key_signatures
      p.items[1].pitch.height.should == 6      
      p.items[3].pitch.height.should == 5
    end
  end

  describe "chord symbols" do
    it "can attach a chord symbol to a note" do
      p = parse_fragment '"Am7"A2D2'
      p.items[0].chord_symbol.should == "Am7"
    end
    it "can handle bass notes" do
      p = parse_fragment '"C/E"G'
      p.items[0].chord_symbol.should == "C/E"
    end
    it "can handle alternate chords" do
      p = parse_fragment '"G(Em/G)"G'
      p.items[0].chord_symbol.should == "G(Em/G)"
    end
    # TODO parse the chord symbols for note, type, bassnote etc
  end

  describe "annotations" do
    it "can place text above a note" do
      p = parse_fragment '"^above"c'
      p.items[0].annotations[0].placement.should == :above
      p.items[0].annotations[0].text.should == "above"
    end
    it "can place text below a note" do
      p = parse_fragment '"_below"c'
      p.items[0].annotations[0].placement.should == :below
      p.items[0].annotations[0].text.should == "below"
    end
    it "can place text to the left and right of a note" do
      p = parse_fragment '"<(" ">)" c'
      p.items[0].annotations[0].placement.should == :left
      p.items[0].annotations[0].text.should == "("
      p.items[0].annotations[1].placement.should == :right
      p.items[0].annotations[1].text.should == ")"
    end
    it "can handle annotations with unspecified placement" do
      p = parse_fragment '"@wherever" c'
      p.items[0].annotations[0].placement.should == :unspecified
      p.items[0].annotations[0].text.should == "wherever"
    end
  end

  it "accepts spacers" do
    parse_fragment "ab y de"
  end
  
  describe "lyrics support" do
    it "parses whole word lyrics" do
      p = parse_fragment "gcea\nw:my dog has fleas"
      # items[4] is the lyrics field
      p.items[4].units.count.should == 4
      p.items[4].units[0].text.should == "my"
      p.items[4].units[1].text.should == "dog"
      p.items[4].units[2].text.should == "has"
      p.items[4].units[3].text.should == "fleas"
    end
  end

end
