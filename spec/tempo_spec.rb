$LOAD_PATH << './'

require 'lib/abc/tempo.rb'

include ABC

describe "Tempo" do
  before do
    @tempo = Tempo.new
  end
  
  describe "unit length" do
    it "defaults to 1/8" do
      @tempo.unit_length.to_s.should == "1/8"
    end
    it "is 1/16 if meter is < 0.75" do
      @tempo.meter = Fraction.new 2, 4
      @tempo.unit_length.to_s.should == "1/16"
    end
    it "is 1/8 if meter is >= 0.75" do
      @tempo.meter = Fraction.new 3, 4
      @tempo.unit_length.to_s.should == "1/8"
    end
    it "can be set explicitly" do
      @tempo.meter = Fraction.new 2, 4
      @tempo.unit_length = Rational 1, 32
      @tempo.unit_length.to_s.should == "1/32"
    end
  end

  describe "note length" do
    it "multiplies correctly" do
      @tempo.note_length(2, 1).to_s.should == "1/4"
      @tempo.note_length(1, 2).to_s.should == "1/16"
      @tempo.meter = Fraction.new 2, 4
      @tempo.note_length(2, 1).to_s.should == "1/8"
      @tempo.unit_length = Rational 1, 4
      @tempo.note_length(3, 2).to_s.should == "3/8"
    end
  end

  it "accepts a label" do
    @tempo.label = "Allegro"
    @tempo.label.should == "Allegro"
  end

  it "has a default bpm of 120" do
    @tempo.bpm.should == 120
    @tempo.bps.should == 2
  end

  it "gives a default beat length equal to unit note length" do
    @tempo.sum_of_beats.to_s.should == "1/8"
    @tempo.unit_length = Rational 1, 4
    @tempo.sum_of_beats.to_s.should == "1/4"
  end

  it "calculates note duration" do
    @tempo.bpm = 60
    @tempo.unit_length = Rational 1, 4
    @tempo.sum_of_beats.to_s.should == "1/4"
    @tempo.note_duration(2, 1).should == 2
  end

end

# TODO: look into how abcjs interprets anomalous note lengths
describe "NoteType" do
  it "recognizes whole notes" do
    n = NoteType.new 1, 1
    n.type.should == 1
    n.dotted.should == false
  end
  it "recognizes half notes" do
    n = NoteType.new 1, 2
    n.type.should == 2
    n.dotted.should == false
  end
  it "recognizes quarter notes" do
    n = NoteType.new 1, 4
    n.type.should == 4
    n.dotted.should == false
  end
  it "recognizes eighth notes" do
    n = NoteType.new 1, 8
    n.type.should == 8
    n.dotted.should == false
  end
  it "recognizes sixteenth notes" do
    n = NoteType.new 1, 16
    n.type.should == 16
    n.dotted.should == false
  end
  it "recognizes 32nd notes" do
    n = NoteType.new 1, 32
    n.type.should == 32
    n.dotted.should == false
  end
  it "recognizes 64th notes" do
    n = NoteType.new 1, 64
    n.type.should == 64
    n.dotted.should == false
  end
  it "recognizes dotted whole notes" do # TODO: is this legal?
    n = NoteType.new 3, 2
    n.type.should == 1
    n.dotted.should == true
  end
  it "recognizes half notes" do
    n = NoteType.new 3, 4
    n.type.should == 2
    n.dotted.should == true
  end
  it "recognizes quarter notes" do
    n = NoteType.new 3, 8
    n.type.should == 4
    n.dotted.should == true
  end
  it "recognizes eighth notes" do
    n = NoteType.new 3, 16
    n.type.should == 8
    n.dotted.should == true
  end
  it "recognizes sixteenth notes" do
    n = NoteType.new 3, 32
    n.type.should == 16
    n.dotted.should == true
  end
  it "recognizes 32nd notes" do
    n = NoteType.new 3, 64
    n.type.should == 32
    n.dotted.should == true
  end
  it "recognizes 64th notes" do
    n = NoteType.new 3, 128
    n.type.should == 64
    n.dotted.should == true
  end
end
