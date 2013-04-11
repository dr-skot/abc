$LOAD_PATH.unshift File.expand_path('.')
require 'spec/parser/spec_helper'

describe "textstring" do
  it "is what typeset text is" do
    p = parse_value "%%text typeset text\n\nX:1\nT:T\nK:C"
    p.sections[0].text.is_a?(TextString).should == true
  end
end
