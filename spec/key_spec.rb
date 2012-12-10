$LOAD_PATH.unshift File.expand_path('../lib')
require 'abc/parser/parsed_elements/key'

include ABC

describe "Key" do
  it "has a signatures constant" do
    Key::SIGNATURES.should include "Em"
    Key::SIGNATURES["Em"].should include "F" => 1
  end

  it "delivers no accidentals when appropriate" do
    expected = {}
    Key.signature("C").should == expected
    Key.signature("C", "major").should == expected    
    Key.signature("C", "ionian").should == expected
    Key.signature("A", "m").should == expected
    Key.signature("A", "minor").should == expected    
    Key.signature("A", "aeolian").should == expected    
    Key.signature("G", "mix").should == expected
    Key.signature("D", "dor").should == expected
    Key.signature("E", "Phr").should == expected
    Key.signature("F", "LYDIAN").should == expected
    Key.signature("B", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 1 sharp when appropriate" do
    expected = { 'F' => 1 }
    Key.signature("G").should == expected
    Key.signature("G", "major").should == expected    
    Key.signature("G", "ionian").should == expected
    Key.signature("E", "m").should == expected
    Key.signature("E", "minor").should == expected    
    Key.signature("E", "aeolian").should == expected    
    Key.signature("D", "mix").should == expected
    Key.signature("A", "dor").should == expected
    Key.signature("B", "Phr").should == expected
    Key.signature("C", "LYDIAN").should == expected
    Key.signature("F#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 2 sharps when appropriate" do
    expected = { 'C' => 1, 'F' => 1 }
    Key.signature("D").should == expected
    Key.signature("D", "major").should == expected    
    Key.signature("D", "ionian").should == expected
    Key.signature("B", "m").should == expected
    Key.signature("B", "minor").should == expected    
    Key.signature("B", "aeolian").should == expected    
    Key.signature("A", "mix").should == expected
    Key.signature("E", "dor").should == expected
    Key.signature("F#", "Phr").should == expected
    Key.signature("G", "LYDIAN").should == expected
    Key.signature("C#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 3 sharps when appropriate" do
    expected = { 'C' => 1, 'F' => 1, 'G' => 1 }
    Key.signature("A").should == expected
    Key.signature("A", "major").should == expected    
    Key.signature("A", "ionian").should == expected
    Key.signature("F#", "m").should == expected
    Key.signature("F#", "minor").should == expected    
    Key.signature("F#", "aeolian").should == expected    
    Key.signature("E", "mix").should == expected
    Key.signature("B", "dor").should == expected
    Key.signature("C#", "Phr").should == expected
    Key.signature("D", "LYDIAN").should == expected
    Key.signature("G#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 4 sharps when appropriate" do
    expected = { 'C' => 1, 'D' => 1, 'F' => 1, 'G' => 1 }
    Key.signature("E").should == expected
    Key.signature("E", "major").should == expected    
    Key.signature("E", "ionian").should == expected
    Key.signature("C#", "m").should == expected
    Key.signature("C#", "minor").should == expected    
    Key.signature("C#", "aeolian").should == expected    
    Key.signature("B", "mix").should == expected
    Key.signature("F#", "dor").should == expected
    Key.signature("G#", "Phr").should == expected
    Key.signature("A", "LYDIAN").should == expected
    Key.signature("D#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 5 sharps when appropriate" do
    expected = { 'C' => 1, 'D' => 1, 'F' => 1, 'G' => 1, 'A' => 1 }
    Key.signature("B").should == expected
    Key.signature("B", "major").should == expected    
    Key.signature("B", "ionian").should == expected
    Key.signature("G#", "m").should == expected
    Key.signature("G#", "minor").should == expected    
    Key.signature("G#", "aeolian").should == expected    
    Key.signature("F#", "mix").should == expected
    Key.signature("C#", "dor").should == expected
    Key.signature("D#", "Phr").should == expected
    Key.signature("E", "LYDIAN").should == expected
    Key.signature("A#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 6 sharps when appropriate" do
    expected = { 'C' => 1, 'D' => 1, 'E' => 1, 'F' => 1, 'G' => 1, 'A' => 1 }
    Key.signature("F#").should == expected
    Key.signature("F#", "major").should == expected    
    Key.signature("F#", "ionian").should == expected
    Key.signature("D#", "m").should == expected
    Key.signature("D#", "minor").should == expected    
    Key.signature("D#", "aeolian").should == expected    
    Key.signature("C#", "mix").should == expected
    Key.signature("G#", "dor").should == expected
    Key.signature("A#", "Phr").should == expected
    Key.signature("B", "LYDIAN").should == expected
    Key.signature("E#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 7 sharps when appropriate" do
    expected = { 'C' => 1, 'D' => 1, 'E' => 1, 'F' => 1, 'G' => 1, 'A' => 1, 'B' => 1 }
    Key.signature("C#").should == expected
    Key.signature("C#", "major").should == expected    
    Key.signature("C#", "ionian").should == expected
    Key.signature("A#", "m").should == expected
    Key.signature("A#", "minor").should == expected    
    Key.signature("A#", "aeolian").should == expected    
    Key.signature("G#", "mix").should == expected
    Key.signature("D#", "dor").should == expected
    Key.signature("E#", "Phr").should == expected
    Key.signature("F#", "LYDIAN").should == expected
    Key.signature("B#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 1 flat when appropriate" do
    expected = { 'B' => -1 }
    Key.signature("F").should == expected
    Key.signature("F", "major").should == expected    
    Key.signature("F", "ionian").should == expected
    Key.signature("D", "m").should == expected
    Key.signature("D", "minor").should == expected    
    Key.signature("D", "aeolian").should == expected    
    Key.signature("C", "mix").should == expected
    Key.signature("G", "dor").should == expected
    Key.signature("A", "Phr").should == expected
    Key.signature("Bb", "LYDIAN").should == expected
    Key.signature("E", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 2 flats when appropriate" do
    expected = { 'E' => -1, 'B' => -1 }
    Key.signature("Bb").should == expected
    Key.signature("Bb", "major").should == expected    
    Key.signature("Bb", "ionian").should == expected
    Key.signature("G", "m").should == expected
    Key.signature("G", "minor").should == expected    
    Key.signature("G", "aeolian").should == expected    
    Key.signature("F", "mix").should == expected
    Key.signature("C", "dor").should == expected
    Key.signature("D", "Phr").should == expected
    Key.signature("Eb", "LYDIAN").should == expected
    Key.signature("A", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 3 flats when appropriate" do
    expected = { 'E' => -1, 'A' => -1, 'B' => -1 }
    Key.signature("Eb").should == expected
    Key.signature("Eb", "major").should == expected    
    Key.signature("Eb", "ionian").should == expected
    Key.signature("C", "m").should == expected
    Key.signature("C", "minor").should == expected    
    Key.signature("C", "aeolian").should == expected    
    Key.signature("Bb", "mix").should == expected
    Key.signature("F", "dor").should == expected
    Key.signature("G", "Phr").should == expected
    Key.signature("Ab", "LYDIAN").should == expected
    Key.signature("D", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 4 flats when appropriate" do
    expected = { 'E' => -1, 'A' => -1, 'B' => -1, 'D' => -1 }
    Key.signature("Ab").should == expected
    Key.signature("Ab", "major").should == expected    
    Key.signature("Ab", "ionian").should == expected
    Key.signature("F", "m").should == expected
    Key.signature("F", "minor").should == expected    
    Key.signature("F", "aeolian").should == expected    
    Key.signature("Eb", "mix").should == expected
    Key.signature("Bb", "dor").should == expected
    Key.signature("C", "Phr").should == expected
    Key.signature("Db", "LYDIAN").should == expected
    Key.signature("G", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 5 flats when appropriate" do
    expected = { 'D' => -1, 'E' => -1, 'G' => -1, 'A' => -1, 'B' => -1 }
    Key.signature("Db").should == expected
    Key.signature("Db", "major").should == expected    
    Key.signature("Db", "ionian").should == expected
    Key.signature("Bb", "m").should == expected
    Key.signature("Bb", "minor").should == expected
    Key.signature("Bb", "aeolian").should == expected    
    Key.signature("Ab", "mix").should == expected
    Key.signature("Gb", "LYDIAN").should == expected
    Key.signature("F", "Phr").should == expected
    Key.signature("Eb", "dor").should == expected
    Key.signature("C", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 6 flats when appropriate" do
    expected = { 'C' => -1, 'D' => -1, 'E' => -1, 'G' => -1, 'A' => -1, 'B' => -1 }
    Key.signature("Gb").should == expected
    Key.signature("Gb", "major").should == expected    
    Key.signature("Gb", "ionian").should == expected
    Key.signature("Eb", "m").should == expected
    Key.signature("Eb", "minor").should == expected
    Key.signature("Eb", "aeolian").should == expected    
    Key.signature("Db", "mix").should == expected
    Key.signature("Cb", "LYDIAN").should == expected
    Key.signature("Bb", "Phr").should == expected
    Key.signature("Ab", "dor").should == expected
    Key.signature("F", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 7 flats when appropriate" do
    expected = { 'C' => -1, 'D' => -1, 'E' => -1, 'F' => -1, 'G' => -1, 'A' => -1, 'B' => -1 }
    Key.signature("Cb").should == expected
    Key.signature("Cb", "major").should == expected    
    Key.signature("Cb", "ionian").should == expected
    Key.signature("Ab", "m").should == expected
    Key.signature("Ab", "minor").should == expected
    Key.signature("Ab", "aeolian").should == expected    
    Key.signature("Gb", "mix").should == expected
    Key.signature("Fb", "LYDIAN").should == expected
    Key.signature("Eb", "Phr").should == expected
    Key.signature("Db", "dor").should == expected
    Key.signature("Bb", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "applies extra accidentals" do
    Key.signature("C", "", { 'D'=> -1 }).should == { 'D' => -1 }
    Key.signature("F", "", { 'B' => 0 }).should == { 'B' => 0 }
  end

  it "supports mode='exp' for explicit accidentals" do
    Key.signature('Gb', 'exp', { 'F' => 1 }).should == { 'F' => 1 }
  end

  it "supports highland pipes" do
    Key.signature("HP").should == { 'C' => 1, 'F' => 1, 'G' => 0 }
    Key.signature("Hp").should == { 'C' => 1, 'F' => 1, 'G' => 0 }
  end

end
