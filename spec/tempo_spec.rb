$LOAD_PATH.unshift File.expand_path('../lib')
require 'abc/parser/parsed_elements/tempo'

include ABC

describe "Tempo" do
  before do
    @tempo = Tempo.new
  end
  
  describe "unit length" do
    it "defaults to 1" do
      @tempo.unit_length.should == 1
    end
    it "can be set explicitly" do
      @tempo.unit_length = Rational 1, 32
      @tempo.unit_length.to_s.should == "1/32"
    end
  end

  describe "note length" do
    it "multiplies correctly" do
      @tempo.note_length(2, 1).to_s.should == "2/1"
      @tempo.note_length(1, 2).to_s.should == "1/2"
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

  it "gives a default beat length of 1" do
    @tempo.beat_length.should == 1
  end

  it "gives beat length equal to unit note length if unit note length given" do
    @tempo.unit_length = Rational 1, 4
    @tempo.beat_length.to_s.should == "1/4"
  end

  it "calculates note duration" do
    @tempo.bpm = 60
    @tempo.unit_length = Rational 1, 4
    @tempo.beat_length.to_s.should == "1/4"
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
