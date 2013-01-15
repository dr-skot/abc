$LOAD_PATH.unshift File.expand_path('.')
require 'spec/parser/spec_helper'

describe "file structure" do
  it "can consist of a single tune with no body" do
    p = parse_value "X:1\nT:Title\nK:C"
    p.is_a?(Tunebook).should == true
    p.tunes.count.should == 1
  end
  it "can include a file header" do
    p = parse_value "C:Madonna\nZ:me\n\nX:1\nT:Like a Prayer\nK:Dm"
    p.composer.should == "Madonna"
    p.transcription.should == "me"
  end
end
