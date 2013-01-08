$LOAD_PATH.unshift File.expand_path('../lib')
require 'abc/model/rest.rb'
include ABC

describe "a rest" do
  it "can be initialized with a length" do
    r = Rest.new(Rational(1, 4))
    r.length.should == Rational(1, 4)
  end
  it "defaults to visible" do
    r = Rest.new(Rational(1, 4))
    r.invisible?.should be_false
  end
  it "can be invisible" do
    r = Rest.new(Rational(1, 4), :invisible => true)
    r.invisible?.should == true
  end
end

describe "a measure rest" do
  it "can be initialized with a length" do
    r = MeasureRest.new(4)
    r.measure_count.should == 4
  end
  it "defaults to visible" do
    r = MeasureRest.new(4)
    r.invisible?.should be_false
  end
  it "can be invisible" do
    r = MeasureRest.new(4, :invisible => true)
    r.invisible?.should == true
  end
end
