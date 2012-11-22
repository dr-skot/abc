$LOAD_PATH << './'

require 'lib/abc/parser.rb'

describe "abc 2.0 draft 4" do

  before do
    @parser = ABC::Parser.new
  end

  def parse(input)
    p = @parser.parse(input)
    p.should_not be(nil), @parser.base_parser.failure_reason
    p
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
      # TODO make this work
      # p.tunes[0].lines[1].items[0].value.should == "Sa-ys my au-l\' wan to your aul\' wan   Will~ye come to the Wa-x-ies dar-gle?"
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


  ## 5. Lyrics
  ## The W field (uppercase W) can be used for lyrics to be printed separately below the tune.
  ## The w field (lowercase w) in the body, supplies a line of lyrics to be aligned syllable by syllable below the previous line of notes. Syllables are not aligned on grace notes and tied notes are treated as two separate notes; slurred or beamed notes are also treated as separate notes in this context. Note that lyrics are always aligned to the beginning of the preceding music line.
  ## It is possible for a music line to be followed by several w fields. This can be used together with the part notation to create verses. The first w field is used the first time that part is played, then the second and so on.
  ## The lyrics lines are treated as an ABC string. Within the lyrics, the words should be separated by one or more spaces and to correctly align them the following symbols may be used:
  ##   -  (hyphen) break between syllables within a word
  ##   _  (underscore) last syllable is to be held for an extra note
  ##   *  one note is skipped (i.e. * is equivalent to a blank syllable)
  ##   ~  appears as a space; aligns multiple words under one note
  ##   \- appears as hyphen; aligns multiple syllables under one note
  ##   |  advances to the next bar
  ## Note that if '-' is preceded by a space or another hyphen, it is regarded as a separate syllable.
  ## When an underscore is used next to a hyphen, the hyphen must always come first.
  ## If there are not as many syllables as notes in a measure, typing a '|' automatically advances to the next bar; if there are enough syllables the '|' is just ignored.
  ## Some examples:
  ##   w: syll-a-ble    is aligned with three notes
  ##   w: syll-a--ble   is aligned with four notes
  ##   w: syll-a -ble   (equivalent to the previous line)
  ##   w: time__        is aligned with three notes
  ##   w: of~the~day    is treated as one syllable (i.e. aligned with one note)
  ##                    but appears as three separate words
  ##   gf|e2dc B2A2|B2G2 E2D2|.G2.G2 GABc|d4 B2
  ##   w: Sa-ys my au-l' wan to your aul' wan\
  ##      Will~ye come to the Wa-x-ies dar-gle?
  ## Please see section Continuation of input lines for the meaning of the backslash (||) character.
  ## If a word starts with a digit, this is interpreted as numbering of a stanza and is pushed forward a bit. In other words, use something like
  ##   w: 1.~Three blind mice
  ## to put a number before "Three."

  describe "lyrics support" do

    it "can set words to notes" do
      p = parse "GCEA\nw:My dog has fleas"
      # puts p.tunes[0].items[0].inspect
      p.tunes[0].notes[0].lyric.text.should == "My"
      p.tunes[0].notes[1].lyric.text.should == "dog"
      p.tunes[0].notes[2].lyric.text.should == "has"
      p.tunes[0].notes[3].lyric.text.should == "fleas"
    end

    it "can set words to notes" do
      p = parse "GCEA\nw:My dog has fleas"
      p.tunes[0].notes[0].lyric.text.should == "My"
      p.tunes[0].notes[1].lyric.text.should == "dog"
      p.tunes[0].notes[2].lyric.text.should == "has"
      p.tunes[0].notes[3].lyric.text.should == "fleas"
    end

    it "can set one syllable to 2 notes" do
      p = parse "FDB\nw:O_ say can you see"
      p.tunes[0].notes[0].lyric.text.should == "O"
      p.tunes[0].notes[0].lyric.note_count.should == 2
      p.tunes[0].notes[1].lyric.should == nil
      p.tunes[0].notes[2].lyric.text.should == "say"
      p.tunes[0].notes[2].lyric.note_count.should == 1
    end

    it "can set one syllable to 3 notes" do
      p = parse "FDdB\nw:O__ say can you see"
      p.tunes[0].notes[0].lyric.text.should == "O"
      p.tunes[0].notes[0].lyric.note_count.should == 3
      p.tunes[0].notes[1].lyric.should == nil
      p.tunes[0].notes[2].lyric.should == nil
      p.tunes[0].notes[3].lyric.text.should == "say"
      p.tunes[0].notes[3].lyric.note_count.should == 1
    end

    it "splits words with hyphen" do
      p = parse "ccGEB\nw:gal-lant-ly stream-ing"
      p.tunes[0].notes[0].lyric.text.should == "gal"
      p.tunes[0].notes[0].lyric.hyphen?.should == true
      p.tunes[0].notes[1].lyric.text.should == "lant"
      p.tunes[0].notes[1].lyric.hyphen?.should == true
      p.tunes[0].notes[2].lyric.text.should == "ly"
      p.tunes[0].notes[2].lyric.hyphen?.should == false
    end

    it "suppports hyphen with underscore" do
      p = parse "d2fedcb4\nw:ban-_ner yet_ wave"
      p.tunes[0].notes[0].lyric.text.should == "ban"
      p.tunes[0].notes[0].lyric.hyphen?.should == true
      p.tunes[0].notes[0].lyric.note_count.should == 2
      p.tunes[0].notes[2].lyric.text.should == "ner"
      p.tunes[0].notes[2].lyric.hyphen?.should == false
    end

    it "stretches with two hyphens" do
      p = parse "d2fedcb4\nw:ban--ner yet_ wave"
      p.tunes[0].notes[0].lyric.text.should == "ban"
      p.tunes[0].notes[0].lyric.hyphen?.should == true
      p.tunes[0].notes[0].lyric.note_count.should == 2
      p.tunes[0].notes[2].lyric.text.should == "ner"
      p.tunes[0].notes[2].lyric.hyphen?.should == false
    end

    it "stretches with space hyphen" do
      p = parse "d2fedcb4\nw:ban -ner yet_ wave"
      p.tunes[0].notes[0].lyric.text.should == "ban"
      p.tunes[0].notes[0].lyric.hyphen?.should == true
      p.tunes[0].notes[0].lyric.note_count.should == 2
      p.tunes[0].notes[2].lyric.text.should == "ner"
      p.tunes[0].notes[2].lyric.hyphen?.should == false
    end

    it "skips notes with *" do
      p = parse "acddc\nw:*see ** see"
      p.tunes[0].notes[0].lyric.should == nil
      p.tunes[0].notes[1].lyric.text.should == "see"
      p.tunes[0].notes[1].lyric.note_count.should == 1
      p.tunes[0].notes[2].lyric.should == nil
      p.tunes[0].notes[3].lyric.should == nil
      p.tunes[0].notes[4].lyric.text.should == "see"
      p.tunes[0].notes[4].lyric.note_count.should == 1
    end

    it "preserves spaces with ~" do
      p = parse "abc\nw:go~on get jiggy with it"
      p.tunes[0].notes[0].lyric.text.should == "go on"
      p.tunes[0].notes[1].lyric.text.should == "get"
    end

    it "escapes hyphens with backslash" do
      p = parse "abc\nw:x\\-ray"
      p.tunes[0].notes[0].lyric.text.should == "x-ray"
    end

    it "advances to the next bar with |" do
      p = parse "abc|def\nw:yeah|yeah"
      p.tunes[0].notes[0].lyric.text.should == "yeah"
      p.tunes[0].notes[0].lyric.note_count.should == 1
      p.tunes[0].notes[1].lyric.should == nil
      p.tunes[0].notes[2].lyric.should == nil
      p.tunes[0].notes[3].lyric.text.should == "yeah"
    end

    # TODO special handling of stanza numbers?

  end


  # 6. Clefs
  # A clef line specification may be provided in K: and V: fields. The general syntax is:
  #   [clef=]<clef name>[<line number>][+8 | -8]
  #     [middle=<pitch>] [transpose=<semitones>]
  #     [stafflines=<lines>]
  # clef name
  #   May be treble, alto, tenor, bass, perc or none. perc selects the drum clef. clef= may be omitted.
  # line number
  #   Indicates on which staff line the base clef is written. Defaults are: treble: 2; alto: 3; tenor: 4; bass: 4.
  # +8 -8
  #   draws '8' above or below the staff. The player will transpose the notes one octave higher or lower.
  # middle=<pitch>
  #   is an alternate way to define the line number of the clef. The pitch indicates what note is displayed on the 3rd line of the staff. Defaults are: treble: B; alto: C; tenor: A,; bass: D,; none: B.
  # transpose=<semitones>
  #   When playing, transpose the current voice by the indicated amount of semitones. This does not affect the printed score. Default is 0.
  # stafflines=<lines>
  #   The number of lines in the staff. Default is 5.
  # Note that the clef, transpose, middle and stafflines specifiers may be used independent of each other.
  # Examples:
  #   [K:   clef=alto]
  #   [K:   perc stafflines=1]
  #   [K:Am transpose=-2]
  #   [V:B  middle=d bass]
  # Note that although this standard supports the drum clef, there is currently no support for special percussion notes.
  # The middle specifier can be handy when working in the bass clef. Setting K:bass middle=d will save you from adding comma specifiers to the notes. The specifier may be abbreviated to m=.
  # The transpose specifier is useful for e.g. a Bb clarinet, for which the music is written in the key of C, although the instrument plays it in the key of Bb:
  #   [V:Clarinet] [K:C transpose=-2]
  # The transpose specifier may be abbreviated to t=.
  # To notate the various standard clefs, one can use the following specifiers:
  # The seven clefs
  #   Name          specifier
  #   Treble        K:treble
  #   Bass          K:bass
  #   Baritone      K:bass3
  #   Tenor	    K:tenor
  #   Alto  	    K:alto
  #   Mezzosoprano  K:alto2
  #   Soprano	    K:alto1
  # More clef names may be allowed in the future, therefore unknown names should be ignored. If the clef is unknown or not specified, the default is treble.
  # Applications may introduce their own clef line specifiers. These specifiers should start with the name of the application, followed a colon, folowed by the name of the specifier.
  # Example:
  #   V:p1 perc stafflines=3 m=C  mozart:noteC=snare-drum
  
  describe "clef support" do

    it "recognizes the simple clef names" do
      p = parse "K:Am clef=treble"
      p.tunes[0].key.clef.name.should == "treble"
      p = parse "K:Am clef=alto"
      p.tunes[0].key.clef.name.should == "alto"
      p = parse "K:Am clef=tenor"
      p.tunes[0].key.clef.name.should == "tenor"
      p = parse "K:Am clef=bass"
      p.tunes[0].key.clef.name.should == "bass"
      p = parse "K:Am clef=perc"
      p.tunes[0].key.clef.name.should == "perc"
      p = parse "K:Am clef=none"
      p.tunes[0].key.clef.name.should == "none"
    end

    it "recognizes a clef name without the clef= specifier" do
      p = parse "K:Am alto"
      p.tunes[0].key.clef.name.should == "alto"
    end

    it "lets you specify line on which to draw the clef" do
      p = parse "K:Am clef=bass4"
      p.tunes[0].key.clef.line.should == 4
    end

    it "has default lines for the basic clefs" do
      p = parse "K:C clef=treble"
      p.tunes[0].key.clef.line.should == 2
      p = parse "K:C clef=alto"
      p.tunes[0].key.clef.line.should == 3
      p = parse "K:C clef=tenor"
      p.tunes[0].key.clef.line.should == 4
      p = parse "K:C clef=bass"
      p.tunes[0].key.clef.line.should == 4
    end

    it "recognizes octave shifts" do
      p = parse "K:Am clef=bass"
      p.tunes[0].key.clef.octave_shift.should == 0
      p = parse "K:Am clef=alto +8"
      p.tunes[0].key.clef.octave_shift.should == 1
      p = parse "K:Am clef=treble -8"
      p.tunes[0].key.clef.octave_shift.should == -1
    end
    
    it "lets you specify the middle pitch" do
      p = parse "K:C clef=treble middle=d"
      p.tunes[0].key.clef.middle.height.should == 14
      p = parse "K:C treble middle=d"
      p.tunes[0].key.clef.middle.height.should == 14
      p = parse "K:C middle=d"
      p.tunes[0].key.clef.middle.height.should == 14
    end

    it "knows the default middle pitch for the basic clefs" do
      p = parse "K:C clef=treble"
      p.tunes[0].key.clef.middle.height.should == 11
      p = parse "K:C clef=alto"
      p.tunes[0].key.clef.middle.height.should == 0
      p = parse "K:C clef=tenor"
      p.tunes[0].key.clef.middle.height.should == -3
      p = parse "K:C clef=bass"
      p.tunes[0].key.clef.middle.height.should == -10
      p = parse "K:C clef=none"
      p.tunes[0].key.clef.middle.height.should == 11
    end

    it "parses transpose information" do
      p = parse "K:C clef=treble transpose=-2"
      p.tunes[0].key.clef.transpose.should == -2
      p = parse "K:C clef=treble t=4"
      p.tunes[0].key.clef.transpose.should == 4
    end

    it "parses number of stafflines" do
      p = parse "K:C clef=treble stafflines=4"
      p.tunes[0].key.clef.stafflines.should == 4
    end

    it "allows unknown clef names" do
      p = parse "K:C baritone"
      p.tunes[0].key.clef.name.should == 'baritone'
    end

    it "defaults to treble" do
      p = parse "K:C"
      p.tunes[0].key.clef.name.should == 'treble'
    end

    it "allows app-specific specifiers" do
      p = parse "K:C clef=perc mozart:noteC=snare-drum"
    end

    it "allows clef specifiers in any order" do
      p = parse "K:C middle=d stafflines=3 bass4 t=-3 +8"
      p.tunes[0].key.clef.name.should == 'bass'
      p.tunes[0].key.clef.middle.note.should == 'D'
      p.tunes[0].key.clef.stafflines.should == 3
      p.tunes[0].key.clef.transpose.should == -3
      p.tunes[0].key.clef.octave_shift.should == 1
    end


    # TODO clef information can be in V: fields too

  end

end
