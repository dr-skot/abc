$LOAD_PATH << './'

require 'lib/abc/parser.rb'

describe "abc 2.0 draft 4" do

  before do
    @parser = ABC::Parser.new
  end

  def parse(input)
    @parser.parse(input)
  end

  ## 2. File structure
  ## An ABC file consists of one or more tune transcriptions. The tunes are separated from each other by blank lines. An ABC file with more than one tune in it, is called an ABC tunebook.

  describe "file structure" do
    it "separates tunes with blank lines" do
      p = parse "X:1\nT:Title\nK:C\nabc\n\nX:2\nT:Title2\nK:Em\n"
      p.tunes.count.should == 2
      p = parse "abc\ndef\n\nabc\n\ndef"
      p.tunes.count.should == 3
    end
  end

  ## The tune itself consists of a header and a body. The header is composed of several field lines, which are further discussed in the section Information fields. The header should start with an X (reference number) field followed by a T (title) field and finish with a K (key) field. The body of the tune, which contains the actual music in ABC notation, should follow immediately after. As will be explained, certain fields may also be used inside this tune body. If the file contains only one tune the X field may be dropped. It is legal to write a tune without a body. This feature can be used to document tunes without transcribing them.

  ## The file may optionally start with a file header, which is a block of consecutive field lines, finished by a blank line. The file header may be used to set default values for the tunes in the file. Such a file header may only appear at the beginning of a file, not between tunes. Of course, tunes may override the file header settings. However, when the end of a tune is reached, the defaults set by the file header are restored. Applications which extract separate tunes from a file, must insert the fields of the original file header, into the header of the extracted tune. However, since users may manually extract tunes, without taking care of the file header, it is advisable not to use file headers in tunebooks that are to be distributed.
  ## It is legal to write free text before or between the tunes of a tunebook. The free text should be separated from the surrounding tunes by blank lines. Programs that are able to print tunebooks, may print the free text sections. The free text is treated as an ABC string. The free text may be interspersed with directives (see section ABC Stylesheet specification) or with Extended information fields; however, the scope of these settings is limited to the text that appears up to the beginning of the next tune. At that point, the defaults set by the file header are restored.



  ## 2.1. Remarks
  ## A '%' symbol will cause the remainder of any input line to be ignored. It can be used to add remarks to the end of an ABC line.
  ## Alternatively, you can use the syntax [r: remarks] to write remarks in the middle of a line of music.

  describe "remarks support" do
    it "ignores remarks in music lines" do
      p = parse "abc %remark\ndef %remark\n"
      p.tunes[0].items[2].pitch.height.should == 12 # c
      p.tunes[0].items[3].pitch.height.should == 14 # d
    end
    it "ignores remarks in header lines" do
      p = parse "T:Jingle Bells % jingle all the way y'all!\n"
      p.title.should == "Jingle Bells"
    end
    it "allows [r: remarks] in music" do
      p = parse "def [r: remarks] abc"
      p.tunes[0].items[2].pitch.height.should == 17 # f
      p.tunes[0].items[3].is_a?(Field).should == true
      p.tunes[0].items[4].pitch.height.should == 9 # a
    end
  end

  ## 2.2. Continuation of input lines
  ## If the last character on a line is a backslash (\), the next line should be appended to the current one, deleting the backslash and the newline, to make one long logical line. There may appear spaces or an end-of-line remark after the backslash: these will be deleted as well. If the user would like to have a space between the two half lines, he should either type one before the backslash, or at the beginning of the next half line.
  ## Example:
  ##   gf|e2dc B2A2|B2G2 E2D2|.G2.G2 \  % continuation
  ##   GABc|d4 B2
  ##   w: Sa-ys my au-l' wan to your aul' wan\
  ##      Will~ye come to the Wa-x-ies dar-gle?
  ## There is no limit to the number of lines that may be appended together.

  describe "line continuation support" do
    it "appends lines with backslash" do
      p = parse "abc\ndef"
      p.tunes[0].lines.count.should == 2
      p.tunes[0].lines[0].items.count.should == 3
      p = parse "abc\\\ndef"
      p.tunes[0].lines.count.should == 1
      p.tunes[0].lines[0].items.count.should == 6
    end
    it "allows space and comments after backslash" do
      p = parse "abc \\ % remark \n def"
      p.tunes[0].lines.count.should == 1
    end
    it "allows continuation in a field" do
      p = parse(["gf|e2dc B2A2|B2G2 E2D2|.G2.G2 \\  % continuation",
                 "GABc|d4 B2",
                 "w: Sa-ys my au-l' wan to your aul' wan\\",
                 "   Will~ye come to the Wa-x-ies dar-gle?"].join("\n"))
      p.should_not be(nil), @parser.base_parser.failure_reason
      p.tunes[0].lines.count.should == 2
      p.tunes[0].lines[1].items[0].is_a?(Field).should == true
      p.tunes[0].lines[1].items[0].value.should == "Sa-ys my au-l' wan to your aul' wan   Will~ye come to the Wa-x-ies dar-gle?"
    end
  end

  ## 2.3. Line breaking
  ## Traditionally, one line of ABC notation corresponded closely to one line of printed music.
  ## It is desirable, however, that ABC applications provide the user with an option to automatically reformat the line breaking, so that the layout of the printed sheet music will look optimal.
  ## To force a line break at all times, an exclamation mark (!) can be used. The ! can be inserted everywhere, where a note group could.

  describe "line breaking support" do
    it "recognizes hard linebreaks" do
      p = parse "abc\ndef!ABC"
      p.tunes[0].lines.count.should == 3
      p.tunes[0].lines[1].hard_break?.should == false
      p.tunes[0].lines[2].hard_break?.should == true
    end
  end


end
