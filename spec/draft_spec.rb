$LOAD_PATH.unshift File.expand_path('../lib')
require 'abc/parser'

describe "abc 2.0 draft 4" do

  before do
    @parser = ABC::Parser.new
  end

  # for convenience
  def parse(input)
    tunebook = @parser.parse(input)     
    tunebook.should_not be(nil), @parser.base_parser.failure_reason
    tunebook
  end

  def fail_to_parse(input)
    p = @parser.parse(input)
    p.should == nil
    p
  end

  def parse_fragment(input)
    tune = @parser.parse_fragment(input)
    tune.should_not be(nil), @parser.base_parser.failure_reason
    tune
  end

  def fail_to_parse_fragment(input)
    p = @parser.parse_fragment(input)
    p.should == nil
    p
  end


  ## 2. File structure
  describe "file structure" do

    ## An ABC file consists of one or more tune transcriptions. The tunes are separated from each other by blank lines. An ABC file with more than one tune in it, is called an ABC tunebook.
    ## The tune itself consists of a header and a body. The header is composed of several field lines, which are further discussed in the section Information fields. The header should start with an X (reference number) field followed by a T (title) field and finish with a K (key) field. The body of the tune, which contains the actual music in ABC notation, should follow immediately after. As will be explained, certain fields may also be used inside this tune body. If the file contains only one tune the X field may be dropped. It is legal to write a tune without a body. This feature can be used to document tunes without transcribing them.
    it "accepts canonical tune headers with X, T, and K fields" do
      p = parse "X:2\nT:Short People\nK:Eb\nabc"
      p.tunes[0].refnum.should == 2
      p.tunes[0].title.should == "Short People"
      p.tunes[0].key.tonic.should == "Eb"
    end
    
    it "accepts a tune header without a body" do
      p = parse "X:2\nT:Short People\nK:Eb\n"
      p.tunes[0].refnum.should == 2
      p.tunes[0].title.should == "Short People"
      p.tunes[0].key.tonic.should == "Eb"
    end
    
    it "separates tunes with blank lines" do
      p = parse "X:1\nT:Title\nK:C\nabc\n\nX:2\nT:Title2\nK:Em\n"
      p.tunes.count.should == 2
    end

    # TODO: allow for this under 2.0?
    # it "allows X field to be dropped if only one tune in file (and refnum defaults to 1)" do
    #  p = parse "T:Happy Birthday\nK:C"
    #  p.tunes[0].refnum.should == 1
    # end
    
    it "accepts no header-only fields after the K: field" do
      fail_to_parse "X:1\nT:T\nK:C\nC:Author\nabc"
    end
    
    it "can handle a standalone body field right after the K: field" do
      p = parse "X:1\nT:T\nK:C\nK:F\nabc"
      p.tunes[0].key.tonic.should == "C"
      p.tunes[0].items[0].value.tonic.should == "F"
    end
    
    it "allows fragment tune data with no header" do
      p = parse_fragment "abc"
    end
        
    ## The file may optionally start with a file header, which is a block of consecutive field lines, finished by a blank line. The file header may be used to set default values for the tunes in the file. Such a file header may only appear at the beginning of a file, not between tunes. Of course, tunes may override the file header settings. However, when the end of a tune is reached, the defaults set by the file header are restored. Applications which extract separate tunes from a file, must insert the fields of the original file header, into the header of the extracted tune. However, since users may manually extract tunes, without taking care of the file header, it is advisable not to use file headers in tunebooks that are to be distributed.

    it "recognizes a file header" do
      p = parse "C:Madonna\nZ:me\n\nX:1\nT:Like a Prayer\nK:Dm"
      p.composer.should == "Madonna"
      p.transcription.should == "me"
    end

    it "does not consider it a file header if it has tune fields in it" do
      fail_to_parse "C:Madonna\nZ:me\nK:C\n\nX:1\nT:Like a Prayer\nK:Dm" # note: K field is only allowed in tune headers
    end 

    it "does not consider it a file header if it's followed by music" do
      fail_to_parse "C:Madonna\nZ:me\nabc\n\nX:1\nT:Like a Prayer\nK:Dm" 
    end

    it "passes file header values to tunes" do
      p = parse "C:Madonna\nZ:me\n\nX:1\nT:T\nK:Dm\nabc" 
      p.composer.should == "Madonna"
      p.tunes[0].composer.should == "Madonna"
    end
    
    it "allows tunes to override the file header" do
      p = parse "C:Madonna\nZ:me\n\nX:1\nT:T\nC:Cher\nK:Eb\nabc" 
      p.composer.should == "Madonna"
      p.tunes[0].composer.should == "Cher"
    end

    it "resets header values with each tune" do
      p = parse "C:Madonna\nZ:me\n\nX:1\nT:T\nC:Cher\nK:Eb\nabc\n\nX:2\nT:T2\nK:C\ndef" 
      p.composer.should == "Madonna"
      p.tunes[0].composer.should == "Cher"
      p.tunes[1].composer.should == "Madonna"
    end
        
    ## It is legal to write free text before or between the tunes of a tunebook. The free text should be separated from the surrounding tunes by blank lines. Programs that are able to print tunebooks, may print the free text sections. The free text is treated as an ABC string. The free text may be interspersed with directives (see section ABC Stylesheet specification) or with Extended information fields; however, the scope of these settings is limited to the text that appears up to the beginning of the next tune. At that point, the defaults set by the file header are restored.

  end


  ## 2.1. Remarks
  ## A '%' symbol will cause the remainder of any input line to be ignored. It can be used to add remarks to the end of an ABC line.
  ## Alternatively, you can use the syntax [r: remarks] to write remarks in the middle of a line of music.

  describe "remarks support" do
    it "ignores remarks in music lines" do
      p = parse_fragment "abc %remark\ndef %remark\n"
      p.items[2].pitch.height.should == 12 # c
      p.items[3].pitch.height.should == 14 # d
    end
    it "ignores remarks in header lines" do
      p = parse "H:Jingle Bells % jingle all the way y'all!\n\nX:1\nT:JB\nK:C"
      p.history.should == "Jingle Bells"
    end
    it "ignores [r: remarks] in music" do
      p = parse_fragment "def [r: remarks] abc"
      p.items[2].pitch.height.should == 17 # f
      p.items[3].pitch.height.should == 21 # a
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
      p = parse_fragment "abc\ndef"
      p.lines.count.should == 2
      p.lines[0].items.count.should == 3
      p = parse_fragment "abc\\\ndef"
      p.lines.count.should == 1
      p.lines[0].items.count.should == 6
    end
    it "can do any number of continuations" do
      p = parse_fragment "abc\\\ndef\\\nabc\\\ndef"
      p.lines.count.should == 1
      p.notes.count.should == 12
    end
    it "allows space and comments after backslash" do
      p = parse_fragment "abc \\ % remark \n def"
      p.lines.count.should == 1
    end
    # TODO should we support this?
    # it "allows continuation in a lyrics line" do
    #   p = parse_fragment(["gf|e2dc B2A2|B2G2 E2D2|.G2.G2 \\  % continuation",
    #              "GABc|d4 B2",
    #              "w: Sa-ys my au-l' wan to your aul' wan\\",
    #              "   Will~ye come to the Wa-x-ies dar-gle?"].join("\n"))
    #   p.lines.count.should == 2
    #   p.lines[1].items[0].is_a?(Field).should == true
    #   p.lines[1].items[0].units.count.should == 19
    # end
  end

  ## 2.3. Line breaking
  ## Traditionally, one line of ABC notation corresponded closely to one line of printed music.
  ## It is desirable, however, that ABC applications provide the user with an option to automatically reformat the line breaking, so that the layout of the printed sheet music will look optimal.
  ## To force a line break at all times, an exclamation mark (!) can be used. The ! can be inserted everywhere, where a note group could.

  describe "line breaking support" do
    it "recognizes hard linebreaks" do
      p = parse_fragment "abc\ndef$ABC"
      p.lines.count.should == 3
      p.lines[1].hard_break?.should == false
      p.lines[2].hard_break?.should == true
    end
  end



  describe "lyrics support" do

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

  end
  
  # 7. Multiple voices
  # The V: field allows the writing of multi-voice music. In multi-voice ABC tunes, the tune body is divided into several sections, each beginning with a V: field. All the notes following such a V: field, up to the next V: field or the end of the tune body, belong to the voice.
  # The basic syntax of the field is:
  #   V:ID
  # where ID can be either a number or a string, that uniquely identifies the voice in question. When using a string, only the first 20 characters of it will be distinguished. The ID will not be printed on the staff; it's only function is to indicate throughout the ABC file, which music line belongs to which voice.
  # Example:
  #   X:1
  #   T:Zocharti Loch
  #   C:Louis Lewandowski (1821-1894)
  #   M:C
  #   Q:1/4=76
  #   %%score (T1 T2) (B1 B2)
  #   V:T1           clef=treble-8  name="Tenore I"   snm="T.I"
  #   V:T2           clef=treble-8  name="Tenore II"  snm="T.II"
  #   V:B1  middle=d clef=bass      name="Basso I"    snm="B.I"
  #   V:B2  middle=d clef=bass      name="Basso II"   snm="B.II"
  #   K:Gm
  #   %            End of header, start of tune body:
  #   % 1
  #   [V:T1]  (B2c2 d2g2)  | f6e2      | (d2c2 d2)e2 | d4 c2z2 |
  #   [V:T2]  (G2A2 B2e2)  | d6c2      | (B2A2 B2)c2 | B4 A2z2 |
  #   [V:B1]       z8      | z2f2 g2a2 | b2z2 z2 e2  | f4 f2z2 |
  #   [V:B2]       x8      |     x8    |      x8     |    x8   |
  #   % 5
  #   [V:T1]  (B2c2 d2g2)  | f8        | d3c (d2fe)  | H d6    ||
  #   [V:T2]       z8      |     z8    | B3A (B2c2)  | H A6    ||
  #   [V:B1]  (d2f2 b2e'2) | d'8       | g3g  g4     | H^f6    ||
  #   [V:B2]       x8      | z2B2 c2d2 | e3e (d2c2)  | H d6    ||
  #   This layout closely resembles printed music, and permits the corresponding notes on different voices to be vertically aligned so that the chords can be read directly from the abc. The addition of single remark lines '%' between the grouped staves, indicating the bar nummers, also makes the source more legible.

  # V: can appear both in the body and the header. In the latter case, V: is used exclusively to set voice properties. For example, the name property in the example above, specifies which label should be printed on the first staff of the voice in question. Note that these properties may be also sget or changed in the tune body. The V: properties will be fully explained in the next section.

  # Please note that the exact grouping of voices on the staff or staves is not specified by V: itself. This may be specified with the %%score stylesheet directive. See section Voice grouping for details. Please see section Instrumentation directives to learn how to assign a General MIDI instrument to a voice, using a %%MIDI stylesheet directive.

  # Although it is not recommended, the tune body of fragment X:1, could also be notated this way:

  # X:2
  # T:Zocharti Loch
  # %...skipping rest of the header...
  # K:Gm
  # %               Start of tune body:
  # V:T1
  #  (B2c2 d2g2) | f6e2 | (d2c2 d2)e2 | d4 c2z2 |
  #  (B2c2 d2g2) | f8 | d3c (d2fe) | H d6 ||
  # V:T2
  #  (G2A2 B2e2) | d6c2 | (B2A2 B2)c2 | B4 A2z2 |
  #  z8 | z8 | B3A (B2c2) | H A6 ||
  # V:B1
  #  z8 | z2f2 g2a2 | b2z2 z2 e2 | f4 f2z2 |
  #  (d2f2 b2e'2) | d'8 | g3g  g4 | H^f6 ||
  # V:B2
  #  x8 | x8 | x8 | x8 |
  #  x8 | z2B2 c2d2 | e3e (d2c2) | H d6 ||

  # In the example above, each V: label occurs only once, and the complete part for that voice follows. The output of tune X:2 will be exactly the same as the ouput of tune X:1; the source code of X:1, however, is much better readable.

  # 7.1. Voice properties

  # V: fields can contain voice specifiers such as name, clef, and so on. For example,

  # V:T name="Tenor" clef=treble-8
  # indicates that voice 'T' will be drawn on a staff labelled "Tenor", using the treble clef with a small '8' underneath. Player programs will transpose the notes by one octave. Possible voice definitions include:

  # name="voice name"
  #   The voice name is printed on the left of the first staff only. The characters '\n' produce a newline int the output.
  # subname="voice subname"
  #   The voice subname is printed on the left of all staves but the first one.
  # stem=up/down
  #   Forces the note stem direction.
  # clef=
  #   Specifies a clef; see section Clefs for details.
  # The name specifier may be abbreviated to nm=. The subname specifier may be abbreviated to snm=.

  # Applications may implement their own specifiers, but must gracefully ignore specifiers they don't understand or implement. This is required for portability of ABC files between applications.

  # 7.2. Breaking lines

  # The rules for breaking lines in multi-voice ABC files are the same as described above. Each line of input may end in a backslash (\) to continue it; lyrics should immediately follow in w: lines (if any). See the example tune Canzonetta.abc.

  # 7.3. Inline fields

  # To avoid ambiguity, inline fields that specify music properties should be repeated in each voice. For example,

  # ...
  # P:C
  # [V:1] C4|[M:3/4]CEG|Gce|
  # [V:2] E4|[M:3/4]G3 |E3 |
  # P:D
  # ...

  describe "multivoice support" do
    it "can parse a V: field in the header" do
      p = parse_fragment "V:T1"
      p.voices['T1'].should_not == nil
    end
    it "only uses 1st 20 characters of id" do
      p = parse_fragment "V:1234567890123456789012345"
      p.voices['1234567890123456789012345'].should == nil
      p.voices['12345678901234567890'].should_not == nil
    end
    # TODO only 1st 20 characters of id
    it "parses name and subname" do
      p = parse_fragment 'V:Ma tenor name="Mama" subname="M"'
      p.voices['Ma'].name.should == 'Mama'
      p.voices['Ma'].subname.should == 'M'
      p = parse_fragment 'V:Da snm="D" nm="Daddy" bass'
      p.voices['Da'].name.should == 'Daddy'
      p.voices['Da'].subname.should == 'D'
    end
    it "parses stem" do
      p = parse_fragment 'V:T1'
      p.voices['T1'].stem.should == nil
      p = parse_fragment 'V:T1 stem=up'
      p.voices['T1'].stem.should == :up
      p = parse_fragment 'V:T1 stem=down'
      p.voices['T1'].stem.should == :down
    end
    # TODO should inherit clef from K field
    it "has a default clef" do
      p = parse_fragment "V:T1"
      p.voices['T1'].clef.name.should == 'treble'
    end
    it "supports clef specifiers" do
      p = parse_fragment 'V:T1 nm="Tenore I" snm="T.I" middle=d stafflines=3 bass4+8 t=-3'
      clef = p.voices['T1'].clef
      clef.name.should == 'bass'
      clef.middle.note.should == 'D'
      clef.stafflines.should == 3
      clef.transpose.should == -3
      clef.octave_shift.should == 1
    end
    it "allocates music to voices" do
      p = parse_fragment "V:A\nV:B\n[V:A]abc\n[V:B]def"
      a = p.voices['A']
      b = p.voices['B']
      a.notes[0].pitch.note.should == "A"
      a.notes[1].pitch.note.should == "B"
      a.notes[2].pitch.note.should == "C"
      b.notes[0].pitch.note.should == "D"
      b.notes[1].pitch.note.should == "E"
      b.notes[2].pitch.note.should == "F"
    end
    it "still works if you don't declare voices in header" do
      p = parse_fragment "[V:A]abc\n[V:B]def"
      a = p.voices['A']
      b = p.voices['B']
      a.notes[0].pitch.note.should == "A"
      a.notes[1].pitch.note.should == "B"
      a.notes[2].pitch.note.should == "C"
      b.notes[0].pitch.note.should == "D"
      b.notes[1].pitch.note.should == "E"
      b.notes[2].pitch.note.should == "F"
    end
    it "knows when there is more than one voice" do
      p = parse_fragment "abc"
      p.many_voices?.should == false
      p = parse_fragment "V:1\nV:2\n[V:1]abc"
      p.many_voices?.should == true
    end
    it "resets key when new voice starts" do
      p = parse_fragment "[V:1]b[K:F]b[V:2]b[K:F]b"
      v1 = p.voices['1']
      v2 = p.voices['2']
      v1.notes[0].pitch.height.should == 23 # B
      v1.notes[1].pitch.height.should == 22 # B flat
      v2.notes[0].pitch.height.should == 23
      v2.notes[1].pitch.height.should == 22
    end
    it "retains key change when voice comes back" do
      p = parse_fragment "[V:1]b[K:F]b[V:2]b[K:F]b[V:1]b[K:C]b"
      v1 = p.voices['1']
      v1.notes[2].pitch.height.should == 22 # B flat
      v1.notes[3].pitch.height.should == 23 # B
    end
    it "resets meter when new voice starts" do
      p = parse_fragment "M:C\n[V:1]Z4[M:3/4]Z4[V:2]Z4[M:3/4]Z4"
      v1 = p.voices['1']
      v2 = p.voices['2']
      v1.notes[0].note_length.should == 4
      v1.notes[1].note_length.should == 3
      v2.notes[0].note_length.should == 4
      v2.notes[1].note_length.should == 3
    end
    it "retains meter change when voice comes back" do
      p = parse_fragment "M:C\n[V:1]Z4[M:3/4]Z4[V:2]Z4[M:3/4]Z4[V:1]Z4[M:C]Z4"
      v1 = p.voices['1']
      v1.notes[2].note_length.should == 3
      v1.notes[3].note_length.should == 4
    end
    it "resets note length when new voice starts" do
      p = parse_fragment "[V:1]a[L:1/4]b[V:2]a[L:1/4]b"
      v1 = p.voices['1']
      v2 = p.voices['2']
      v1.notes[0].note_length.should == Rational(1, 8)
      v1.notes[1].note_length.should == Rational(1, 4)
      v2.notes[0].note_length.should == Rational(1, 8)
      v2.notes[1].note_length.should == Rational(1, 4)
    end
    it "retains meter change when voice comes back" do
      p = parse_fragment "[V:1]a[L:1/4]b[V:2]a[L:1/4]b[V:1]a[L:1/16]b"
      v1 = p.voices['1']
      v1.notes[2].note_length.should == Rational(1, 4)
      v1.notes[3].note_length.should == Rational(1, 16)
    end
    it "uses first voice if you for tune.notes[]" do
      p = parse_fragment "[V:1]a[V:2]b[V:1]a[V:2]b"
      p.notes.should == p.voices["1"].notes
    end
    it "allows V: fields as standalones" do
      p = parse_fragment "K:C\nV:A\na\nV:B\nb"
      p.voices['A'].notes[0].pitch.note.should == 'A'
      p.voices['B'].notes[0].pitch.note.should == 'B'
    end

    # TODO what if the tune has voices but some notes occcur before the first voice field?
    it "has a default voice if no voices specified" do
      p = parse_fragment "abc"
      p.voices[""].items.should == p.items
    end
  end

  # 7.4. Voice overlay
  # The & operator may be used to temporarily overlay several voices within one measure. The & operator sets the time point of the music back to the previous bar line, and the notes which follow it form a temporary voice in parallel with the preceding one. This may only be used to add one complete bar's worth of music for each &.
  # Example:
  # A2 | c d e f g  a  &\
  #      A A A A A  A  &\
  #      F E D C B, A, |]
  # It can also be used to overlay a pattern of chord symbols on a melody line:
  # B4              z   +5+c (3BAG &\
  # "Em" x2 "G7" x2 "C" x4         |
  # Likewise, the & operator may be used in w: lyrics and in s: symbol lines, to provide a separate line of lyrics and symbols to each of the overlayed voices:
  #    g4 f4 | e6 e2  &\
  #    (d8   | c6) c2
  # w: ha-la-| lu-yoh &\
  #    lu-   |   -yoh
  # In meter free music, invisible bar line signs '[|]' may be used instead of regular ones.
  
  describe "voice overlay support" do
    it "allows multiple voices in a single bar" do
      p = parse_fragment "|a b c & A B C|"
      p.measures[0].overlays?.should == true
      p.measures[0].overlays.count.should == 1
      p.measures[0].notes[0].pitch.height.should == 21
      p.measures[0].overlays[0].notes[0].pitch.height.should == 9
    end
    # TODO move this to a different test section
    it "allows bars[] as a synonym for measures[]" do
      p = parse_fragment "|a b c & A B C|"
      p.bars.should == p.measures
      p.voices[""].bars.should == p.voices[""].measures
    end

    # TODO allow fields in voice overlays, rather than just notes? eg what if we want a key change in overlaid voices?

  end

end
