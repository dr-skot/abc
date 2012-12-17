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
    p.value
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
         Rrhythm Ssource Ztranscription}.each do |field|
        label = field[0]
        name = field[1..-1]
        p = parse "#{label}:File Header\n\nX:1\nT:T1\nK:C\n\nX:2\nT:T2\n#{label}:Tune Header\n#{label}:again\nK:D"
        p.postprocess
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
      p.postprocess
      p.items[0].pitch.height.should == 10
    end

    it "retains accidentals within a measure when applying key signature" do
      p = parse_fragment "K:F\nB=BB"
      p.postprocess
      p.items[0].pitch.height.should == 10
      p.items[1].pitch.height.should == 11
      p.items[2].pitch.height.should == 11
    end

    it "resets accidentals at end of measure" do
      p = parse_fragment "K:F\nB=B|B"
      p.postprocess
      p.items[0].pitch.height.should == 10
      p.items[1].pitch.height.should == 11
      p.items[3].pitch.height.should == 10
    end

    it "does not reset accidentals at dotted bar line" do
      p = parse_fragment "K:F\nB=B.|B"
      p.postprocess
      p.items[0].pitch.height.should == 10
      p.items[1].pitch.height.should == 11
      p.items[3].pitch.height.should == 11
    end

    it "can apply key signatures to all tunes in tunebook" do
      p = parse "X:1\nT:T\nK:Eb\nA=A^AA\n\nX:2\nT:T2\nK:F\nB"
      p.postprocess
      p.tunes[0].items[0].pitch.height.should == 8
      p.tunes[0].items[1].pitch.height.should == 9
      p.tunes[0].items[2].pitch.height.should == 10
      p.tunes[0].items[3].pitch.height.should == 10
      p.tunes[1].items[0].pitch.height.should == 10
    end

    it "does not apply key signature from previous tune" do
      p = parse "X:1\nT:T\nK:Eb\nA\n\n\nX:2\nT:T2\nK:C\nA"
      p.postprocess
      p.tunes[0].items[0].pitch.height.should == 8
      p.tunes[1].items[0].pitch.height.should == 9
    end

    it "changes key signature when inline K: field found in tune body" do
      p = parse_fragment "X:1\nK:C\nC[K:A]C"
      p.postprocess
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




  it "accepts spacers" do
    parse_fragment "ab y de"
  end
  
end
