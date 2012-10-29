$LOAD_PATH << './'

require 'lib/abc/key-signature.rb'

include ABC

describe "KeySignature" do
  it "has a signatures constant" do
    SIGNATURES.should include "Em"
    SIGNATURES["Em"].should include "F" => 1
  end

  it "delivers no accidentals when appropriate" do
    expected = {}
    KeySignature.signature("C").should == expected
    KeySignature.signature("C", "major").should == expected    
    KeySignature.signature("C", "ionian").should == expected
    KeySignature.signature("A", "m").should == expected
    KeySignature.signature("A", "minor").should == expected    
    KeySignature.signature("A", "aeolian").should == expected    
    KeySignature.signature("G", "mix").should == expected
    KeySignature.signature("D", "dor").should == expected
    KeySignature.signature("E", "Phr").should == expected
    KeySignature.signature("F", "LYDIAN").should == expected
    KeySignature.signature("B", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 1 sharp when appropriate" do
    expected = { 'F' => 1 }
    KeySignature.signature("G").should == expected
    KeySignature.signature("G", "major").should == expected    
    KeySignature.signature("G", "ionian").should == expected
    KeySignature.signature("E", "m").should == expected
    KeySignature.signature("E", "minor").should == expected    
    KeySignature.signature("E", "aeolian").should == expected    
    KeySignature.signature("D", "mix").should == expected
    KeySignature.signature("A", "dor").should == expected
    KeySignature.signature("B", "Phr").should == expected
    KeySignature.signature("C", "LYDIAN").should == expected
    KeySignature.signature("F#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 2 sharps when appropriate" do
    expected = { 'C' => 1, 'F' => 1 }
    KeySignature.signature("D").should == expected
    KeySignature.signature("D", "major").should == expected    
    KeySignature.signature("D", "ionian").should == expected
    KeySignature.signature("B", "m").should == expected
    KeySignature.signature("B", "minor").should == expected    
    KeySignature.signature("B", "aeolian").should == expected    
    KeySignature.signature("A", "mix").should == expected
    KeySignature.signature("E", "dor").should == expected
    KeySignature.signature("F#", "Phr").should == expected
    KeySignature.signature("G", "LYDIAN").should == expected
    KeySignature.signature("C#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 3 sharps when appropriate" do
    expected = { 'C' => 1, 'F' => 1, 'G' => 1 }
    KeySignature.signature("A").should == expected
    KeySignature.signature("A", "major").should == expected    
    KeySignature.signature("A", "ionian").should == expected
    KeySignature.signature("F#", "m").should == expected
    KeySignature.signature("F#", "minor").should == expected    
    KeySignature.signature("F#", "aeolian").should == expected    
    KeySignature.signature("E", "mix").should == expected
    KeySignature.signature("B", "dor").should == expected
    KeySignature.signature("C#", "Phr").should == expected
    KeySignature.signature("D", "LYDIAN").should == expected
    KeySignature.signature("G#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 4 sharps when appropriate" do
    expected = { 'C' => 1, 'D' => 1, 'F' => 1, 'G' => 1 }
    KeySignature.signature("E").should == expected
    KeySignature.signature("E", "major").should == expected    
    KeySignature.signature("E", "ionian").should == expected
    KeySignature.signature("C#", "m").should == expected
    KeySignature.signature("C#", "minor").should == expected    
    KeySignature.signature("C#", "aeolian").should == expected    
    KeySignature.signature("B", "mix").should == expected
    KeySignature.signature("F#", "dor").should == expected
    KeySignature.signature("G#", "Phr").should == expected
    KeySignature.signature("A", "LYDIAN").should == expected
    KeySignature.signature("D#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 5 sharps when appropriate" do
    expected = { 'C' => 1, 'D' => 1, 'F' => 1, 'G' => 1, 'A' => 1 }
    KeySignature.signature("B").should == expected
    KeySignature.signature("B", "major").should == expected    
    KeySignature.signature("B", "ionian").should == expected
    KeySignature.signature("G#", "m").should == expected
    KeySignature.signature("G#", "minor").should == expected    
    KeySignature.signature("G#", "aeolian").should == expected    
    KeySignature.signature("F#", "mix").should == expected
    KeySignature.signature("C#", "dor").should == expected
    KeySignature.signature("D#", "Phr").should == expected
    KeySignature.signature("E", "LYDIAN").should == expected
    KeySignature.signature("A#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 6 sharps when appropriate" do
    expected = { 'C' => 1, 'D' => 1, 'E' => 1, 'F' => 1, 'G' => 1, 'A' => 1 }
    KeySignature.signature("F#").should == expected
    KeySignature.signature("F#", "major").should == expected    
    KeySignature.signature("F#", "ionian").should == expected
    KeySignature.signature("D#", "m").should == expected
    KeySignature.signature("D#", "minor").should == expected    
    KeySignature.signature("D#", "aeolian").should == expected    
    KeySignature.signature("C#", "mix").should == expected
    KeySignature.signature("G#", "dor").should == expected
    KeySignature.signature("A#", "Phr").should == expected
    KeySignature.signature("B", "LYDIAN").should == expected
    KeySignature.signature("E#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 7 sharps when appropriate" do
    expected = { 'C' => 1, 'D' => 1, 'E' => 1, 'F' => 1, 'G' => 1, 'A' => 1, 'B' => 1 }
    KeySignature.signature("C#").should == expected
    KeySignature.signature("C#", "major").should == expected    
    KeySignature.signature("C#", "ionian").should == expected
    KeySignature.signature("A#", "m").should == expected
    KeySignature.signature("A#", "minor").should == expected    
    KeySignature.signature("A#", "aeolian").should == expected    
    KeySignature.signature("G#", "mix").should == expected
    KeySignature.signature("D#", "dor").should == expected
    KeySignature.signature("E#", "Phr").should == expected
    KeySignature.signature("F#", "LYDIAN").should == expected
    KeySignature.signature("B#", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 1 flat when appropriate" do
    expected = { 'B' => -1 }
    KeySignature.signature("F").should == expected
    KeySignature.signature("F", "major").should == expected    
    KeySignature.signature("F", "ionian").should == expected
    KeySignature.signature("D", "m").should == expected
    KeySignature.signature("D", "minor").should == expected    
    KeySignature.signature("D", "aeolian").should == expected    
    KeySignature.signature("C", "mix").should == expected
    KeySignature.signature("G", "dor").should == expected
    KeySignature.signature("A", "Phr").should == expected
    KeySignature.signature("Bb", "LYDIAN").should == expected
    KeySignature.signature("E", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 2 flats when appropriate" do
    expected = { 'E' => -1, 'B' => -1 }
    KeySignature.signature("Bb").should == expected
    KeySignature.signature("Bb", "major").should == expected    
    KeySignature.signature("Bb", "ionian").should == expected
    KeySignature.signature("G", "m").should == expected
    KeySignature.signature("G", "minor").should == expected    
    KeySignature.signature("G", "aeolian").should == expected    
    KeySignature.signature("F", "mix").should == expected
    KeySignature.signature("C", "dor").should == expected
    KeySignature.signature("D", "Phr").should == expected
    KeySignature.signature("Eb", "LYDIAN").should == expected
    KeySignature.signature("A", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 3 flats when appropriate" do
    expected = { 'E' => -1, 'A' => -1, 'B' => -1 }
    KeySignature.signature("Eb").should == expected
    KeySignature.signature("Eb", "major").should == expected    
    KeySignature.signature("Eb", "ionian").should == expected
    KeySignature.signature("C", "m").should == expected
    KeySignature.signature("C", "minor").should == expected    
    KeySignature.signature("C", "aeolian").should == expected    
    KeySignature.signature("Bb", "mix").should == expected
    KeySignature.signature("F", "dor").should == expected
    KeySignature.signature("G", "Phr").should == expected
    KeySignature.signature("Ab", "LYDIAN").should == expected
    KeySignature.signature("D", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 4 flats when appropriate" do
    expected = { 'E' => -1, 'A' => -1, 'B' => -1, 'D' => -1 }
    KeySignature.signature("Ab").should == expected
    KeySignature.signature("Ab", "major").should == expected    
    KeySignature.signature("Ab", "ionian").should == expected
    KeySignature.signature("F", "m").should == expected
    KeySignature.signature("F", "minor").should == expected    
    KeySignature.signature("F", "aeolian").should == expected    
    KeySignature.signature("Eb", "mix").should == expected
    KeySignature.signature("Bb", "dor").should == expected
    KeySignature.signature("C", "Phr").should == expected
    KeySignature.signature("Db", "LYDIAN").should == expected
    KeySignature.signature("G", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 5 flats when appropriate" do
    expected = { 'D' => -1, 'E' => -1, 'G' => -1, 'A' => -1, 'B' => -1 }
    KeySignature.signature("Db").should == expected
    KeySignature.signature("Db", "major").should == expected    
    KeySignature.signature("Db", "ionian").should == expected
    KeySignature.signature("Bb", "m").should == expected
    KeySignature.signature("Bb", "minor").should == expected
    KeySignature.signature("Bb", "aeolian").should == expected    
    KeySignature.signature("Ab", "mix").should == expected
    KeySignature.signature("Gb", "LYDIAN").should == expected
    KeySignature.signature("F", "Phr").should == expected
    KeySignature.signature("Eb", "dor").should == expected
    KeySignature.signature("C", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 6 flats when appropriate" do
    expected = { 'C' => -1, 'D' => -1, 'E' => -1, 'G' => -1, 'A' => -1, 'B' => -1 }
    KeySignature.signature("Gb").should == expected
    KeySignature.signature("Gb", "major").should == expected    
    KeySignature.signature("Gb", "ionian").should == expected
    KeySignature.signature("Eb", "m").should == expected
    KeySignature.signature("Eb", "minor").should == expected
    KeySignature.signature("Eb", "aeolian").should == expected    
    KeySignature.signature("Db", "mix").should == expected
    KeySignature.signature("Cb", "LYDIAN").should == expected
    KeySignature.signature("Bb", "Phr").should == expected
    KeySignature.signature("Ab", "dor").should == expected
    KeySignature.signature("F", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

  it "delivers 7 flats when appropriate" do
    expected = { 'C' => -1, 'D' => -1, 'E' => -1, 'F' => -1, 'G' => -1, 'A' => -1, 'B' => -1 }
    KeySignature.signature("Cb").should == expected
    KeySignature.signature("Cb", "major").should == expected    
    KeySignature.signature("Cb", "ionian").should == expected
    KeySignature.signature("Ab", "m").should == expected
    KeySignature.signature("Ab", "minor").should == expected
    KeySignature.signature("Ab", "aeolian").should == expected    
    KeySignature.signature("Gb", "mix").should == expected
    KeySignature.signature("Fb", "LYDIAN").should == expected
    KeySignature.signature("Eb", "Phr").should == expected
    KeySignature.signature("Db", "dor").should == expected
    KeySignature.signature("Bb", "loCoMOTIVE only 1st 3 letters matter").should == expected
  end

end
