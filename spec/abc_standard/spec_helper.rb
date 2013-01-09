require 'abc/parser'
include ABC

def parser
  @parser = ABC::Parser.new
end

# for convenience
def parse(input)
  p = parser.parse(input)
  p.should_not be(nil), @parser.base_parser.failure_reason
  p.value.is_a?(Tunebook).should == true
  p
end

def parse_value(input)
  parse(input).value
end

def fail_to_parse(input)
  p = parser.parse(input)
  p.should == nil
  p
end

def parse_fragment(input)
  p = parser.parse_fragment(input)
  p.should_not be(nil), @parser.base_parser.failure_reason
  p.value.is_a?(Tune).should == true
  p
end

def parse_value_fragment(input)
  parse_fragment(input).value
end

def fail_to_parse_fragment(input)
  p = parser.parse_fragment(input)
  p.should == nil
  p
end

