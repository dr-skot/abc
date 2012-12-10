$LOAD_PATH.unshift File.expand_path('../lib')
require 'abc/parser/parsed_elements/clef'

include ABC

describe 'Clef' do
  it "defaults to treble" do
    Clef.new.name.should == 'treble'
  end
  it "can take any name" do
    Clef.new(:name => 'ouagadougou').should_not == nil
  end
  it "knows default lines for each clef type" do
    Clef.new.line.should == 2
    Clef.new(:name => 'alto').line.should == 3
    Clef.new(:name => 'tenor').line.should == 4
    Clef.new(:name => 'bass').line.should == 4
  end
  it "knows default lines for each clef type" do
    Clef.new.line.should == 2
    Clef.new(:name => 'alto').line.should == 3
    Clef.new(:name => 'tenor').line.should == 4
    Clef.new(:name => 'bass').line.should == 4
  end
  it "can take a 'line' option" do
    Clef.new(:line => 3).line.should == 3
  end
  it "defaults to no octave shift" do
    Clef.new.octave_shift.should == 0
  end
  it "can take an octave option" do
    Clef.new(:octave => -1).octave_shift.should == -1
  end
  it "knows default middle pitches for each clef type" do
    Clef.new.middle_pitch.note.should == 'B'
    Clef.new.middle_pitch.octave.should == 0
    Clef.new(:name => 'alto').middle_pitch.note.should == 'C'
    Clef.new(:name => 'alto').middle_pitch.octave.should == 0
    Clef.new(:name => 'tenor').middle_pitch.note.should == 'A'
    Clef.new(:name => 'tenor').middle_pitch.octave.should == -1
    Clef.new(:name => 'bass').middle_pitch.note.should == 'D'
    Clef.new(:name => 'bass').middle_pitch.octave.should == -1
    Clef.new(:name => 'none').middle_pitch.note.should == 'B'
    Clef.new(:name => 'none').middle_pitch.octave.should == 0
  end
end
