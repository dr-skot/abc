$LOAD_PATH << './'

require 'lib/abc/parser.rb'

describe "abc 2.0 draft 4" do

  before do
    @parser = ABC::Parser.new
  end

  def parse(input)
    @parser.parse(input)
  end

  ## 2.1. Remarks
  ## A '%' symbol will cause the remainder of any input line to be ignored. It can be used to add remarks to the end of an ABC line.
  ## Alternatively, you can use the syntax [r: remarks] to write remarks in the middle of a line of music.

  describe "remarks support" do
    it "ignores remarks in music lines" do
      p = parse "abc %remark\ndef %remark\n"
      p.tunes[0].items[3].is_a?(TuneSpace).should == true
      p.tunes[0].items[4].is_a?(NoteOrRest).should == true
    end
    it "ignores remarks in header lines" do
      p = parse "T:Jingle Bells % jingle all the way y'all!\n"
      p.title.should == "Jingle Bells"
    end
    it "allows [r: remarks] in music" do
      p = parse "def [r: remarks] abc"
      p.tunes[0].items[3].is_a?(TuneSpace).should == true
      p.tunes[0].items[4].is_a?(Field).should == true
      p.tunes[0].items[5].is_a?(TuneSpace).should == true
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
