require 'abc/parser'
include ABC

def parser
  @parser = ABC::Parser.new
end

# for convenience
def parse(input)
  p = parser.parse(input)
  p.should_not be(nil), @parser.base_parser.failure_reason
  p.is_a?(ABC::Tunebook).should == true
  p
end
#module_function :parse

def fail_to_parse(input)
  p = parser.parse(input)
  p.should == nil
  p
end
#module_function :fail_to_parse

def parse_fragment(input)
  tune = parser.parse_fragment(input)
  tune.should_not be(nil), @parser.base_parser.failure_reason
  tune.is_a?(ABC::Tune).should == true
  tune
end
#module_function :parse_fragment

def fail_to_parse_fragment(input)
  tune = parser.parse_fragment(input)
  tune.should == nil
  tune
end
#module_function :fail_to_parse_fragment

