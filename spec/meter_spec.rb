$LOAD_PATH << './'

require 'lib/abc/meter.rb'

include ABC

describe "Meter" do
  it "can be initialized with a numerator and denominator" do
    m = Meter.new 6, 8
    m.numerator.should == 6
    m.denominator.should == 8
    m.symbol.should == nil
  end
  it "can be initialized with :cut" do
    m = Meter.new :cut
    m.numerator.should == 2
    m.denominator.should == 4
    m.symbol.should == :cut
  end
  it "does not show :cut symbol if initialized as 2/4" do
    m = Meter.new 2, 4
    m.numerator.should == 2
    m.denominator.should == 4
    m.symbol.should == nil
  end
  it "can be initialized with :common" do
    m = Meter.new :common
    m.numerator.should == 4
    m.denominator.should == 4
    m.symbol.should == :common
  end
  it "does not show :common symbol if initialized as 4/4" do
    m = Meter.new 4, 4
    m.numerator.should == 4
    m.denominator.should == 4
    m.symbol.should == nil
  end
  it "understands complex meter" do
    m = Meter.new [3,2,3], 8
    m.numerator.should == 8
    m.denominator.should == 8
    m.complex_numerator.should == [3,2,3]
  end
  it "can be free" do
    m = Meter.new :free
    m.symbol.should == :free
    m.numerator.should == nil
    m.denominator.should == nil
  end
  it "gives the correct default unit note length" do
    Meter.new(:free).default_unit_note_length.should == Rational(1, 8)
    Meter.new(:cut).default_unit_note_length.should == Rational(1, 16)
    Meter.new(:common).default_unit_note_length.should == Rational(1, 8)
    Meter.new(6 ,8).default_unit_note_length.should == Rational(1, 8)
    Meter.new(5 ,8).default_unit_note_length.should == Rational(1, 16)
    Meter.new([3, 2, 3], 8).default_unit_note_length.should == Rational(1, 8)
    Meter.new([2, 1, 2], 8).default_unit_note_length.should == Rational(1, 16)
  end
end
