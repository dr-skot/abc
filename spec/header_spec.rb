$LOAD_PATH.unshift File.expand_path('../lib')
require 'abc/parser/parsed_elements/header'
require 'abc/parser/parsed_elements/field'

include ABC

describe "header" do
  describe "::fields" do

    it "returns an empty list if no fields" do
      h = Header.new
      h.fields.should == []
    end

    it "returns all fields if no args" do
      h = Header.new([Field.new('T','title'), Field.new('T','subtitle'), Field.new('K','key')])
      h.fields.count.should == 3
      h.fields.map { |f| f.identifier }.join("").should == 'TTK'
    end

    it "can find fields with a specified identifier" do
      h = Header.new([Field.new('T','title'), Field.new('T','subtitle'), Field.new('K','key')])
      h.fields('T').count.should == 2
      h.fields('K').count.should == 1
    end

    it "returns an empty list if the identifier isn't found" do
      h = Header.new([Field.new('T','title'), Field.new('T','subtitle'), Field.new('K','key')])
      h.fields('X').should == []
    end

    it "can find several identifiers at once" do
      h = Header.new([Field.new('T','title'), Field.new('X',1), Field.new('K','key')])
      h.fields('X', 'T').map { |f| f.identifier }.join("").should == 'TX'
    end

    it "can find fields of a specified type" do
      h = Header.new([Field.new('T','',:title), Field.new('T','',:title), Field.new('K','',:key)])
      h.fields(:title).count.should == 2
      h.fields(:key).count.should == 1
    end

    it "can find several types at once" do
      h = Header.new([Field.new('T','',:title), Field.new('X',1,:refnum), Field.new('K','',:key)])
      h.fields(:refnum, :key).map { |f| f.identifier }.join("").should == 'XK'
    end

  end

  describe "::field" do

    it "returns a field if one match find" do
      h = Header.new([Field.new('T','title'), Field.new('T','subtitle'), Field.new('K','key')])
      h.field('K').value.should == 'key'
    end

    it "returns a list if more than one match found" do
      h = Header.new([Field.new('T','title'), Field.new('T','subtitle'), Field.new('K','key')])
      h.field('T').count.should == 2
    end

    it "returns nil if no match found" do
      h = Header.new([Field.new('T','title'), Field.new('T','subtitle'), Field.new('K','key')])
      h.field('X').should == nil
    end

    it "can find several identifiers at once" do
      h = Header.new([Field.new('T','title'), Field.new('X',1), Field.new('K','key')])
      h.field('X', 'T').map { |f| f.identifier }.join("").should == 'TX'
      h.field('K', 'L', 'M').value.should == 'key'
    end

  end


  describe "::values" do

    it "returns an empty list if no fields" do
      h = Header.new
      h.values.should == []
    end

    it "returns all values if no args" do
      h = Header.new([Field.new('T','title'), Field.new('T','subtitle'), Field.new('K','key')])
      h.values.join(' ').should == 'title subtitle key'
    end

    it "can find fields with a specified identifier" do
      h = Header.new([Field.new('T','title'), Field.new('T','subtitle'), Field.new('K','key')])
      h.values('T').join(" ").should == 'title subtitle'
      h.values('K').join(" ").should == 'key'
    end

    it "returns an empty list if the identifier isn't found" do
      h = Header.new([Field.new('T','title'), Field.new('T','subtitle'), Field.new('K','key')])
      h.values('X').should == []
    end

    it "can find several identifiers at once" do
      h = Header.new([Field.new('T','title'), Field.new('X',1), Field.new('K','key')])
      h.values('X', 'T').join(' ').should == 'title 1'
    end

    it "can find fields of a specified type" do
      h = Header.new([Field.new('T',1,:title), Field.new('T',2,:title), Field.new('K',3,:key)])
      h.values(:title).should == [1, 2]
      h.values(:key).should == [3]
    end

    it "can find several types at once" do
      h = Header.new([Field.new('T',1,:title), Field.new('X',2,:refnum), Field.new('K',3,:key)])
      h.values(:refnum, :key).should == [2, 3]
    end

  end

  
  describe "::value" do

    it "returns a scalar value if one match find" do
      h = Header.new([Field.new('T','title'), Field.new('T','subtitle'), Field.new('K','key')])
      h.value('K').should == 'key'
    end

    it "returns a list if more than one match found" do
      h = Header.new([Field.new('T','title'), Field.new('T','subtitle'), Field.new('K','key')])
      h.value('T').should == ['title', 'subtitle']
    end

    it "returns nil if no match found" do
      h = Header.new([Field.new('T','title'), Field.new('T','subtitle'), Field.new('K','key')])
      h.value('X').should == nil
    end

    it "can find several identifiers at once" do
      h = Header.new([Field.new('T','title'), Field.new('X',1), Field.new('K','key')])
      h.value('X', 'T').should == ['title', 1]
      h.value('K', 'L', 'M').should == 'key'
    end

  end

  describe "master header" do
    it "finds headers in the master header" do
      m = Header.new([Field.new('T',1)])
      h = Header.new([], m)
      h.value('T').should == 1
    end
    it "finds headers in the both headers by default" do
      m = Header.new([Field.new('T',1)])
      h = Header.new([Field.new('T',2)], m)
      h.value('T').should == [1, 2]
    end
    it "can allow local fields to replace master header fields" do
      m = Header.new([Field.new('T',1)])
      h = Header.new([Field.new('T',2)], m)
      h.value_replace_master('T').should == 2
    end
  end

end
