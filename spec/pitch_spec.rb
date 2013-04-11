$LOAD_PATH.unshift File.expand_path('../lib')
require 'abc/model/pitch'

include ABC

describe 'Pitch' do
  it "defaults to octave 0" do
    Pitch.new('C').octave.should == 0
  end
  it "places B above C in octave 0" do
    Pitch.new('B').height.should == 11
  end
end
