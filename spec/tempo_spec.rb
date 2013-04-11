$LOAD_PATH.unshift File.expand_path('../lib')
require 'abc/model/tempo'

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


