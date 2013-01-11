# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('.')
require 'spec/parser/spec_helper'

describe "ignored char" do
  it "generates a warning" do
    p = parse_fragment "c@*;#?@"
    p.warnings.count.should == 6
  end
end
