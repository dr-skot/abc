require 'abc/parser'
include ABC

def t(*args)
  I18n.t(*args)
end

def field(type, identifier)
  t('abc.field_type', type:type, identifier:identifier)
end

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
  p = parse(input)
  p.errors.should == []
  p.value
end

def fail_to_parse(input)
  p = parser.parse(input)
  (p == nil).should == true
  p
end

def parse_fragment(input)
  p = parser.parse_fragment(input)
  p.should_not be(nil), @parser.base_parser.failure_reason
  p.value.is_a?(Tune).should == true
  p
end

def parse_value_fragment(input)
  p = parse_fragment(input)
  p.errors.should == []
  p.value
end

def fail_to_parse_fragment(input)
  p = parser.parse_fragment(input)
  (p == nil).should == true
  p
end

