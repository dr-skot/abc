$LOAD_PATH << './'
require 'polyglot'
require 'treetop'
require 'lib/abc/abc-2.0-draft4.treetop'
require 'lib/abc/syntax-nodes.rb'
require 'lib/abc/parser.rb'
require 'lib/abc/voice.rb'
require 'lib/abc/part.rb'
require 'lib/abc/measure.rb'
require 'lib/abc/meter.rb'
require 'lib/abc/key.rb'


describe "abc 2.1" do

  before do
    @parser = ABC::Parser.new
  end

  # for convenience
  def parse(input)
    p = @parser.parse(input)
    p.should_not be(nil), @parser.base_parser.failure_reason
    p.is_a?(ABC::Tunebook).should == true
    p
  end

  def fail_to_parse(input)
    p = @parser.parse(input)
    p.should == nil
    p
  end

  def parse_fragment(input)
    tune = @parser.parse_fragment(input)
    tune.should_not be(nil), @parser.base_parser.failure_reason
    tune.is_a?(ABC::Tune).should == true
    tune
  end

  def fail_to_parse_fragment(input)
    tune = @parser.parse_fragment(input)
    tune.should == nil
    tune
  end


  # 2.2 Abc file structure
  # An abc file consists of one or more abc tune transcriptions, optionally interspersed with free text and typeset text annotations. It may optionally start with a file header to set up default values for processing the file.
  # The file header, abc tunes and text annotations are separated from each other by empty lines (also known as blank lines).
  # An abc file with more than one tune in it is called an abc tunebook.
  
  describe "file structure" do
    it "must include at least 1 tune" do
      fail_to_parse ""
      fail_to_parse "C:Madonna"
      fail_to_parse "free text"
      fail_to_parse "%%text typeset text"
    end
    it "can consist of a single tune with no body" do
      p = parse "X:1\nT:Title\nK:C"
      p.is_a?(ABC::Tunebook).should == true
      p.tunes.count.should == 1
    end
    it "can consist of a single tune with a body" do
      p = parse "X:1\nT:Title\nK:C\nabc"
      p.tunes.count.should == 1
    end
    it "can consist of several tunes with or without bodies" do
      p = parse "X:1\nT:Title\nK:C\nabc\n\nX:2\nT:T2\nK:D\n\nX:3\nT:T3\nK:none\ncba"
      p.tunes.count.should == 3
    end
    it "can include a file header" do
      p = parse "C:Madonna\nZ:me\n\nX:1\nT:Like a Prayer\nK:Dm"
      p.composer.should == "Madonna"
      p.transcription.should == "me"
    end
    it "can include free text" do
      p = parse "free text\n\nX:1\nT:T\nK:C"
      p.sections.count.should == 2
      p.sections[0].is_a?(FreeText).should == true
    end
    it "can include typeset text annotations" do
      p = parse "N:fileheader\n\n%%text blah\n\nX:1\nT:T\nK:C"
      p.sections.count.should == 2
      p.sections[0].is_a?(TypesetText).should == true
    end
    it "doesn't confuse a bad header with free text" do
      fail_to_parse "X:1\n\nX:2\nT:T\nK:C"
      # TODO return a legible warning in such cases
    end
  end


  # 2.2.1 Abc tune
  # An abc tune itself consists of a tune header and a tune body, terminated by an empty line or the end of the file. It may also contain comment lines or stylesheet directives.
  # The tune header is composed of several information field lines, which are further discussed in information fields. The tune header should start with an X:(reference number) field followed by a T:(title) field and finish with a K:(key) field.
  # The tune body, which contains the music code, follows immediately after. Certain fields may also be used inside the tune body - see use of fields within the tune body.
  # It is legal to write an abc tune without a tune body. This feature can be used to document tunes without transcribing them.
  # Abc music code lines are those lines in the tune body which give notes, bar lines and other musical symbols - see the tune body for details. In effect, music code is the contents of any line which is not an information field, stylesheet directive or comment line.
  
  describe "tune" do
    it "can contain comment lines in the header" do
      p = parse "X:1\nT:T\n% comment\nK:D\nabc\ndef"
      p.tunes.count.should == 1
      p.tunes[0].key.tonic.should == "D"
    end
    it "can contain comment lines in the tune" do
      p = parse "X:1\nT:T\nK:D\nabc\n% more comments\ndef"
      p.tunes.count.should == 1
      p.tunes[0].items[3].pitch.note.should == "D"
    end
    it "can start with comment lines" do
      p = parse "%comment\n%comment\nX:1\nT:T\nK:D\nabc\ndef"
      p.tunes.count.should == 1
      p.tunes[0].key.tonic.should == "D"
    end
    it "can end with comment lines" do
      p = parse "X:1\nT:T\nK:D\nabc\ndef\n%comment\n%comment"
      p.tunes.count.should == 1
      p.tunes[0].key.tonic.should == "D"
    end
    # TODO should we allow tunes to *start* with comments?
    it "can appear with no body" do
      p = parse "X:1\nT:T\nK:C\n"
    end
  end


  # 2.2.2 File header
  # The file may optionally start with a file header (immediately after the version field), consisting of a block of consecutive information fields, stylesheet directives, or both, terminated with an empty line. The file header is used to set default values for the tunes in the file.
  # The file header may only appear at the beginning of a file, not between tunes.
  # Settings in a tune may override the file header settings, but when the end of a tune is reached the defaults set by the file header are reinstated.
  # Applications which extract separate tunes from a file must insert the fields of the original file header into the header of the extracted tune. However, since users may manually extract tunes without regard to the file header, it is not recommended to use a file header in an abc tunebook that is to be distributed.

  define "file header" do
    it "cannot appear between tunes" do
      fail_to_parse "X:1\nT:Like a Prayer\nK:Dm\n\nC:Madonna\nZ:me\n\nX:2\nT:Like A Virgin\nK:F"
      # TODO generate a legible warning in this case
    end
    it "can contain comment lines" do
      p = parse "C:Madonna\n%comment\nZ:me\n\nX:1\nT:Like a Prayer\nK:Dm"
      p.composer.should == "Madonna"
      p.transcription.should == "me"
    end
    it "can start with comment lines" do
      p = parse "%comment\n%comment\nC:Madonna\nZ:me\n\nX:1\nT:Like a Prayer\nK:Dm"
      p.composer.should == "Madonna"
      p.transcription.should == "me"
    end
    it "can end with comment lines" do
      p = parse "C:Madonna\nZ:me\n%comment\n%comment\n\nX:1\nT:Like a Prayer\nK:Dm"
      p.composer.should == "Madonna"
      p.transcription.should == "me"
    end
    it "cannot contain tune fields" do
      fail_to_parse "C:Madonna\nZ:me\nK:C\n\nX:1\nT:Like a Prayer\nK:Dm" # note: K field is only allowed in tune headers
    end 
    it "cannot be followed by music" do
      fail_to_parse "C:Madonna\nZ:me\nabc\n\nX:1\nT:Like a Prayer\nK:Dm" 
    end
    it "passes its settings to all tunes" do
      p = parse "C:Madonna\nZ:me\n\nX:1\nT:T\nK:Dm\nabc" 
      p.composer.should == "Madonna"
      p.tunes[0].composer.should == "Madonna"
    end    
    it "can be overridden by the tune header" do
      p = parse "C:Madonna\nZ:me\n\nX:1\nT:T\nC:Cher\nK:Eb\nabc" 
      p.composer.should == "Madonna"
      p.tunes[0].composer.should == "Cher"
    end
    it "resets overridden values with each new tune" do
      p = parse "C:Madonna\nZ:me\n\nX:1\nT:T\nC:Cher\nK:Eb\nabc\n\nX:2\nT:T2\nK:C\ndef" 
      p.composer.should == "Madonna"
      p.tunes[0].composer.should == "Cher"
      p.tunes[1].composer.should == "Madonna"
    end
  end


  # 2.2.3 Free text and typeset text
  # The terms free text and typeset text refer to any text not directly included within the information fields in a tune header. Typically such text is used for annotating abc tunebooks; free text is for annotating the abc file but is not included in the typeset score, whereas typeset text is intended for printing out.
  # Free text is just that. It can be included anywhere in an abc file, after the file header, but must be separated from abc tunes, typeset text and the file header by empty lines. Typically it is used for annotating the abc file but in principle can be any text not containing information fields.
  # Comment: Since raw html markup and email headers are treated as free text (provided they don't inadvertently contain information fields) this means that abc software can process a wide variety of text-based input files just by ignoring non-abc code.
  # By default free text is not included in the printed score, although typesetting software may offer the option to print it out (e.g. via a command line switch or GUI checkbox). In this case, the software should treat the free text as a text string, but may format it in any way it chooses.
  # Typeset text is any text specified using text directives. It may be inserted anywhere in an abc file after the file header, either separated from tunes by empty lines, or included in the tune header or tune body.
  # Typeset text should be printed by typesetting programs although its exact position in the printed score is program-dependent.
  # Typeset text that is included in an abc tune (i.e. within the tune header or tune body), must be retained by any programs, such as databasing software, that splits an abc file into separate abc tunes.

  # TODO write the coverage for this once we have typeset text support in place


  # 2.2.4 Empty lines and line-breaking
  # Empty lines (also known as blank lines) are used to separate abc tunes, free text and the file header. They also aid the readability of abc files.
  # Lines that consist entirely of white-space (space and tab characters) are also regarded as empty lines.
  # Line-breaks (also known as new lines, line feeds, carriage returns, end-of-lines, etc.) can be used within an abc file to aid readability and, if required, break up long input lines - see continuation of input lines.
  # More specifically, line-breaks in the music code can be used to structure the abc transcription and, by default, generate line-breaks in the printed music. For more details see typesetting line-breaks.

  describe "empty line" do
    it "breaks sections" do
      p = parse "free_text\n\nX:1\nT:T\nK:C\nabc"
      p.sections.count.should == 2
    end
    it "can contain whitespace" do
      p = parse "free_text\n  \t \nX:1\nT:T\nK:C\nabc"
      p.sections.count.should == 2
    end
    it "can contain whitespace after a tune" do
      p = parse "X:1\nT:T\nK:C\nabc\n     \nX:2\nT:T2\nK:D\ndef"
      p.tunes.count.should == 2
    end
    it "can contain whitespace after a tune with no body" do
      p = parse "X:1\nT:T\nK:C\n     \nX:2\nT:T2\nK:D\ndef"
      p.tunes.count.should == 2
    end
  end


  # 2.2.5 Comments and remarks
  # A percent symbol (%) will cause the remainder of any input line to be ignored. It can be used to add a comment to the end of an abc line or as a comment line in its own right. (To get a percent symbol, type \% - see text strings.)
  # Alternatively, you can use the syntax [r:remark] to write a remark in the middle of a line of music.
  # Example:
  #   |:DEF FED| % this is an end of line comment
  #   % this is a comment line
  #   DEF [r:and this is a remark] FED:|
  # Abc code which contains comments and remarks should be processed in exactly the same way as it would be if all the comments and remarks were removed (although, if the code is preprocessed, and comments are actually removed, the stylesheet directives should be left in place).
  # Important clarification: lines which just contain a comment are processed as if the entire line were removed, even if the comment is preceded by white-space (i.e. the % symbol is the not first character). In other words, removing the comment effectively removes the entire line and so no empty line is introduced.
  
  describe "comment" do
    it "can appear at the end of an abc line" do
      p = parse_fragment "abc % comment\ndef"
      p.lines.count.should == 2
      p.items[3].pitch.note.should == "D"
    end
    it "can appear as a line in its own right" do
      p = parse_fragment "abc\n   % comment\ndef"
      p.lines.count.should == 2
      p.items[3].pitch.note.should == "D"
    end
    it "does not introduce an empty line" do
      fail_to_parse "X:1\nT:T\nK:C\n  %comment\nX:2\nT:T2\nK:D"
    end
  end

  # TODO instead of creating a field remark should be ignored
  describe "remark" do
    it "can appear in the middle of a music line" do
      p = parse_fragment "def [r: remarks] abc"
      p.items[2].pitch.height.should == 17 # f
      p.items[3].is_a?(Field).should == true
      p.items[4].pitch.height.should == 9 # a
    end
  end

  # 2.2.6 Continuation of input lines
  # It is sometimes necessary to tell abc software that an input line is continued on the next physical line(s) in the abc file, so that the two (or more) lines are treated as one. In abc 2.0 there was a universal continuation character (see outdated continuations) for this purpose, but it was decided that this was both unnecessary and confusing.
  # In abc 2.1, there are ways of continuing each of the 4 different input line types: music code, information fields, comments and stylesheet directives.
  # In abc music code, by default, line-breaks in the code generate line-breaks in the typeset score and these can be suppressed by using a backslash (or by telling abc typesetting software to ignore line-breaks using I:linebreak $ or I:linebreak <none>) - see typesetting line-breaks for full details.
  # Comment for programmers: The backslash effectively acts as a continuation character for music code lines, although, for those used to encountering it in other computer language contexts, its use is very abc-specific. In particular it can continue music code lines through information fields, comments and stylesheet directives.
  # The 3 other input line types can be continued as follows:
  #   information fields can be continued using +: at the start of the following line - see field continuation;
  #   comments can easily be continued by adding a % symbol at the start of the following line - since they are ignored by abc software it doesn't matter how many lines they are split into;
  #   most stylesheet directives are too short to require a continuation syntax, but if one is required then use the I:<directive> form (see I:instruction), in place of %%<directive> and continue the line as a field - see field continuation.
  # Comment for developers: Unlike other languages, and because of the way in which both information fields and music code can be continued through comments, stylesheet directives and (in the case of music code) information fields, it is generally not possible to parse abc files by pre-processing continuations into single lines.
  # Note that, with the exception of abc music code, continuations are unlikely to be needed often. Indeed in most cases it should be possible, although not necessarily desirable, to write very long input lines, since most abc editing software will display them as wrapped within the text editor window.
  # Recommendation: Despite there being no limit on line length in abc files, it is recommended that users avoid writing abc code with very long lines. In particular, judiciously applied line-breaks can aid the (human) readability of abc code. More importantly, users who send abc tunes with long lines should be aware that email software sometimes introduces additional line-breaks into lines with more than 72 characters and these may even cause errors when the resulting tune is processed.

  describe "music line continuation" do
    it "combines two lines with a backslash" do
      p = parse_fragment "abc\ndef"
      p.lines.count.should == 2
      p.lines[0].items.count.should == 3
      p = parse_fragment "abc\\\ndef"
      p.lines.count.should == 1
      p.lines[0].items.count.should == 6
    end
    it "can combine more than two lines" do
      p = parse_fragment "abc\\\ndef\\\nabc\\\ndef"
      p.lines.count.should == 1
      p.notes.count.should == 12
    end
    it "allows space and comments after the backslash" do
      p = parse_fragment "abc \\ % remark \n def"
      p.lines.count.should == 1
    end
    it "works across information fields" do
      p = parse_fragment "abc \\ \nM:3/4\ndef"
      p.lines.count.should == 1
    end
    # TODO works across stylesheet directives
    it "works across comment lines" do
      p = parse_fragment "abc \\ \n % remark \n def"
      p.lines.count.should == 1
    end
    it "puts information field with following music line" do
      p = parse_fragment "abc\nM:3/4\ndef"
      p.lines.count.should == 2
      p.lines[1].items[0].is_a?(Field).should == true
    end
  end

  # TODO move this to proper section
  describe "information field continuation" do
    it "combines string-based fields with '+:'" do
      p = parse_fragment "H:let me tell you a little\n+:about this song"
      p.history.should == "let me tell you a little about this song"
    end
    it "combines lyric lines with '+:'" do
      p = parse_fragment "GCEA\nw:my dog\n+:has fleas"
      p.notes[3].lyric.text.should == "fleas"
    end
    it "combines symbol lines with '+:'" do
      p = parse_fragment "GCEA\ns:**\n+:*+f+"
      p.notes[3].decorations[0].symbol.should == "f"
    end
  end


  # 2.3.1 Embedded abc fragment
  # An abc fragment is a partial abc tune. It may contain a partial tune header with no body or a tune body with optional tune header information fields.
  # Example 1: A fragment with no tune header:
  # <div class="abc-fragment">
  # CDEF GABc|
  # </div>
  # Example 2: A fragment with a partial tune header:
  # <div class="abc-fragment">
  # T:Major scale in D
  # K:D
  # DEFG ABcd|
  # </div>
  # Unless T:, M: and K: fields are present, a fragment is assumed to describe a stave in the treble clef with no title, no meter indication and no key signature, respectively.
  # An abc fragment does not require an empty line to mark the end of the tune body if it is terminated by the document markup.
  # Note for developers: For processing as an abc tune, the parsing code is notionally assumed to add empty X:, T: and K: fields, if these are missing. However, since the processing generally takes place internally within a software package, these need not be added in actuality.
  
  describe "fragment" do
    it "can contain a partial tune header with no body" do
      tune = parse_fragment "K:D"
      tune.key.tonic.should == "D"
      tune = parse_fragment "T:Love Stinks"
      tune.title.should == "Love Stinks"
      tune = parse_fragment "X:2"
      tune.refnum.should == 2
    end
    it "can contain a partial tune header with a body" do
      tune = parse_fragment "K:D\nabc"
      tune.key.tonic.should == "D"
    end
    it "can contain a tune body with no header" do
      parse_fragment "abc"
    end
    it "has a refnum of 1 if X field is missing" do
      tune = parse_fragment "abc"
      tune.refnum.should == 1
    end
    it "has the special key NONE if K field is missing" do
      tune = parse_fragment "abc"
      tune.key.should == Key::NONE
    end
    it "uses the treble clef if the K field is missing" do
      tune = parse_fragment "abc"
      tune.key.clef.name.should == "treble"
      # TODO tune itself should have a clef attribute
    end
    it "has nil title if T field is missing" do
      tune = parse_fragment "abc"
      tune.title.should == nil
      # TODO should it be "" instead?
    end
  end


  # 3. Information fields
  # Any line beginning with a letter in the range A-Z or a-z and immediately followed by a colon (:) is an information field. Information fields are used to notate things such as composer, meter, etc. In fact anything that isn't music.
  # An information field may also be inlined in a tune body when enclosed by [ and ] - see use of fields within the tune body.
  # Many of these information field identifiers are currently unused so, in order to extend the number of information fields in the future, programs that comply with this standard must ignore the occurrence of information fields not defined here (although they should give a non-fatal error message to warn the user, in case the field identifier is an error or is unsupported).
  # Some information fields are permitted only in the file or tune header and some only in the tune body, while others are allowed in both locations. information field identifiers A-G, X-Z and a-g, x-z are not permitted in the body to avoid confusion with note symbols, rests and spacers.
  # Users who wish to use abc notation solely for transcribing (rather than documenting) tunes can ignore most of the information fields. For this purpose all that is really needed are the X:(reference number), T:(title), M:(meter), L:(unit note length) and K:(key) information fields, plus if applicable C:(composer) and w: or W: (words/lyrics, respectively within or after the tune).
  # Recommendation for newcomers: A good way to find out how to use the fields is to look at the example files, sample abc tunes (in particular English.abc), and try out some examples.
  # The information fields are summarised in the following table and discussed in description of information fields and elsewhere.
  # The table illustrates how the information fields may be used in the tune header and whether they may also be used in the tune body (see use of fields within the tune body for details) or in the file header (see abc file structure).
  
  describe "information field" do
    it "can have an unrecognized identifier in the file header" do
      p = parse "J:unknown field\n\nX:1\nT:T\nK:C"
      # TODO use a string for this instead of regex
      p.field_value(/J/).should == 'unknown field'
    end
    it "can have an unrecognized identifier in the tune header" do
      p = parse "X:1\nT:T\nJ:unknown field\nK:C"
      p.tunes[0].field_value(/J/).should == 'unknown field'
    end
    it "can have an unrecognized identifier in the tune body" do
      p = parse "X:1\nT:T\nK:C\nabc\nJ:unknown field\ndef"
      p.tunes[0].items[3].is_a?(Field).should == true
      p.tunes[0].items[3].value.should == 'unknown field'
    end
    it "can have an unrecognized identifier inline in the tune" do
      p = parse "X:1\nT:T\nK:C\nabc[J:unknown field]def"
      p.tunes[0].items[3].is_a?(Field).should == true
      p.tunes[0].items[3].value.should == 'unknown field'
    end
  end


  # Repeated information fields
  # All information fields, with the exception of X:, may appear more than once in an abc tune.
  # In the case of all string-type information fields, repeated use in the tune header can be regarded as additional information - for example, a tune may be known by many titles and an abc tune transcription may appear at more than one URL (using the F: field). Typesetting software which prints this information out may concatenate all string-type information fields of the same kind, separated by semi-colons (;), although the initial T:(title) field should be treated differently, as should W:(words) fields - see typesetting information fields.
  # Certain instruction-type information fields, in particular I:, m:, U: and V:, may also be used multiple times in the tune header to set up different instructions, macros, user definitions and voices. However, if two such fields set up the same value, then the second overrides the first.
  # Example: The second I:linebreak instruction overrides the first.
  # I:linebreak <EOL>
  # I:linebreak <none>
  # Comment: The above example should not generate an error message. The user may legitimately wish to test the effect of two such instructions; having them both makes switching from one to another easy just by changing their order.
  # Other instruction-type information fields in the tune header also override the previous occurrence of that field.
  # Within the tune body each line of code is processed in sequence. Therefore, with the exception of s:(symbol line), w:(words) and W:(words) which have their own syntax, the same information field may occur a number of times, for example to change key, meter, tempo or voice, and each occurrence has the effect of overriding the previous one, either for the remainder of the tune, or until the next occurrence. See use of fields within the tune body for more details.

  describe "information field repeating" do
    it "indicates multiple values for string fields" do
      p = parse "C:John Lennon\nC:Paul McCartney\n\nX:1\nT:\nK:C"
      p.composer.should == ["John Lennon", "Paul McCartney"]
    end
    it "overrides previous value for meter fields" do
      p = parse "M:C\nM:3/4\n\nX:1\nT:\nK:C"
      p.meter.measure_length.should == Rational(3, 4)
   end
  end


  # 3.1.1 X: - reference number
  # The X: (reference number) field is used to assign to each tune within a tunebook a unique reference number (a positive integer), for example: X:23.
  # The X: field is also used to indicate the start of the tune (and hence the tune header), so all tunes must start with an X: field and only one X: field is allowed per tune.
  # The X: field may be empty, although this is not recommended.

  describe "X: (reference number) field" do
    it "cannot be repeated" do
      fail_to_parse "X:1\nT:Title\nX:2\nK:C"
      # TODO error message
    end
    it "must be an integer" do
      fail_to_parse "X:one\nT:Title\nK:C"
      # TODO error message
    end
    it "can be empty" do
      p = parse "X:\nT:Title\nK:C"
      p.tunes[0].refnum.should == nil
    end
  end


  # 3.1.2 T: - tune title
  # A T: (title) field must follow immediately after the X: field; it is the human identifier for the tune (although it may be empty).
  # Some tunes have more than one title and so this field can be used more than once per tune to indicate alternative titles.
  # The T: field can also be used within a tune to name parts of a tune - in this case it should come before any key or meter changes.
  # See typesetting information fields for details of how the title and alternatives are included in the printed score.

  describe "T: (title) field" do
    it "can be empty" do
      p = parse "X:1\nT:\nK:C"
      p.tunes[0].title.should == ""
    end
    it "can be repeated" do
      p = parse "X:1\nT:T1\nT:T2\nK:C"
      p.tunes[0].title.should == ["T1", "T2"]
    end
    it "can be used within a tune" do
      p = parse "X:1\nT:T\nK:C\nT:Part1\nabc\nT:Part2\ndef"
      p.tunes[0].items[0].is_a?(Field).should == true
      p.tunes[0].items[0].value.should == "Part1"
    end
  end

  # 3.1.3 C: - composer
  # The C: field is used to indicate the composer(s).
  # See typesetting information fields for details of how the composer is included in the printed score.

  describe "C: (composer) field" do
    it "is recognized" do
      p = parse_fragment "C:Brahms"
      p.composer.should == "Brahms"
    end
  end


  # 3.1.4 O: - origin
  # The O: field indicates the geographical origin(s) of a tune.
  # If possible, enter the data in a hierarchical way, like:
  # O:Canada; Nova Scotia; Halifax.
  # O:England; Yorkshire; Bradford and Bingley.
  # Recommendation: It is recommended to always use a ";" (semi-colon) as the separator, so that software may parse the field. However, abc 2.0 recommended the use of a comma, so legacy files may not be parse-able under abc 2.1.
  # This field may be especially useful for traditional tunes with no known composer.
  # See typesetting information fields for details of how the origin information is included in the printed score.

  describe "O: (origin) field" do
    it "is recognized" do
      p = parse_fragment "O:Canada; Nova Scotia; Halifax.\nO:England; Yorkshire; Bradford and Bingley."
      p.origin.should == ["Canada; Nova Scotia; Halifax.", "England; Yorkshire; Bradford and Bingley."]
    end
  end


  # 3.1.5 A: - area
  # Historically, the A: field has been used to contain area information (more specific details of the tune origin). However this field is now deprecated and it is recommended that such information be included in the O: field.

  describe "A: (area) field" do
    it "is recognized" do
      p = parse_fragment "O:Nova Scotia\nA:Halifax"
      p.area.should == "Halifax"
    end
  end


  # 3.1.6 M: - meter
  # The M: field indicates the meter. Apart from standard meters, e.g. M:6/8 or M:4/4, the symbols M:C and M:C| give common time (4/4) and cut time (2/2) respectively. The symbol M:none omits the meter entirely (free meter).
  # It is also possible to specify a complex meter, e.g. M:(2+3+2)/8, to make explicit which beats should be accented. The parentheses around the numerator are optional.
  # The example given will be typeset as:
  # 2 + 3 + 2
  #     8
  # When there is no M: field defined, free meter is assumed (in free meter, bar lines can be placed anywhere you want).

  describe "M: (meter) field" do
    it "can be a numerator and denominator" do
      p = parse_fragment "M:6/8\nabc"
      p.meter.numerator.should == 6
      p.meter.denominator.should == 8
    end
    it "can be \"C\", meaning common time" do
      p = parse_fragment "M:C\nabc"
      p.meter.numerator.should == 4
      p.meter.denominator.should == 4
      p.meter.symbol.should == :common
    end
    it "can be \"C|\", meaning cut time" do
      p = parse_fragment "M:C|\nabc"
      p.meter.numerator.should == 2
      p.meter.denominator.should == 4
      p.meter.symbol.should == :cut
    end
    it "can handle complex meter with parentheses" do
      p = parse_fragment "M:(2+3+2)/8\nabc"
      p.meter.complex_numerator.should == [2,3,2]
      p.meter.numerator.should == 7
      p.meter.denominator.should == 8
    end
    it "can handle complex meter without parentheses" do
      p = parse_fragment "M:2+3+2/8\nabc"
      p.meter.complex_numerator.should == [2,3,2]
      p.meter.numerator.should == 7
      p.meter.denominator.should == 8
    end
    it "defaults to free meter" do
      p = parse_fragment "abc"
      p.meter.symbol.should == :free
    end
    it "can be explicitly defined as none" do
      p = parse_fragment "M:none\nabc"
      p.meter.symbol.should == :free
    end
  end


  # 3.1.7 L: - unit note length
  # The L: field specifies the unit note length - the length of a note as represented by a single letter in abc - see note lengths for more details.
  # Commonly used values for unit note length are L:1/4 - quarter note (crotchet), L:1/8 - eighth note (quaver) and L:1/16 - sixteenth note (semi-quaver). L:1 (whole note) - or equivalently L:1/1, L:1/2 (minim), L:1/32 (demi-semi-quaver), L:1/64, L:1/128, L:1/256 and L:1/512 are also available, although L:1/64 and shorter values are optional and may not be provided by all software packages.
  # If there is no L: field defined, a unit note length is set by default, based on the meter field M:. This default is calculated by computing the meter as a decimal: if it is less than 0.75 the default unit note length is a sixteenth note; if it is 0.75 or greater, it is an eighth note. For example, 2/4 = 0.5, so, the default unit note length is a sixteenth note, while for 4/4 = 1.0, or 6/8 = 0.75, or 3/4= 0.75, it is an eighth note. For M:C (4/4), M:C| (2/2) and M:none (free meter), the default unit note length is 1/8.
  # A meter change within the body of the tune will not change the unit note length.
  
  describe "L: (unit note length) field" do
    it "knows its value" do
      p = parse_fragment "L:1/4"
      p.unit_note_length.should == Rational(1, 4)
    end
    it "accepts whole numbers" do
      p = parse_fragment "L:1\nabc"
      p.unit_note_length.should == 1
    end
    it "defaults to 1/16 if meter is less than 0.75" do
      p = parse_fragment "M:74/100\n"
      p.unit_note_length.should == Rational(1, 16)
    end
    it "defaults to 1/8 if meter is 0.75 or greater" do
      p = parse_fragment "M:3/4\n"
      p.unit_note_length.should == Rational(1, 8)
    end
    it "will not change note lengths when the meter changes in the tune" do
      p = parse_fragment "M:3/4\nK:C\na\nM:2/4\nb"
      p.notes[0].note_length.should == Rational(1, 8)
      p.notes[1].note_length.should == Rational(1, 8)
    end
  end


  # 3.1.8 Q: - tempo
  # The Q: field defines the tempo in terms of a number of beats per minute, e.g. Q:1/2=120 means 120 half-note beats per minute.
  # There may be up to 4 beats in the definition, e.g:
  # Q:1/4 3/8 1/4 3/8=40
  # This means: play the tune as if Q:5/4=40 was written, but print the tempo indication using separate notes as specified by the user.
  # The tempo definition may be preceded or followed by an optional text string, enclosed by quotes, e.g.
  # Q: "Allegro" 1/4=120
  # Q: 3/8=50 "Slowly"
  # It is OK to give a string without an explicit tempo indication, e.g. Q:"Andante".
  # Finally note that some previous Q: field syntax is now deprecated (see outdated information field syntax).

  describe "Q: (tempo) field" do
    it "can be of the simple form beat=bpm" do
      p = parse_fragment "X:1\nQ:1/4=120"
      p.tempo.beat_length.should == Rational(1, 4)
      p.tempo.beat_parts.should == [Rational(1, 4)]
      p.tempo.bpm.should == 120
    end
    it "can divide the beat into parts" do
      p = parse_fragment "X:1\nQ:1/4 3/8 1/4 3/8=40"
      p.tempo.beat_length.should == Rational(5, 4)
      p.tempo.beat_parts.should == 
        [Rational(1, 4), Rational(3, 8), Rational(1, 4), Rational(3, 8)]
      p.tempo.bpm.should == 40
    end
    it "can take a label before the tempo indicator" do
      p = parse_fragment "X:1\nQ:\"Allegro\" 1/4=120"
      p.tempo.label.should == "Allegro"
    end
    it "can take a label after the tempo indicator" do
      p = parse_fragment "X:1\nQ:3/8=50 \"Slowly\""
      p.tempo.label.should == "Slowly"
    end
    it "can take a label without an explicit tempo indication" do
      p = parse_fragment "Q:\"Andante\""
      p.tempo.label.should == "Andante"
    end    
  end


  # 3.1.9 P: - parts
  # VOLATILE: For music with more than one voice, interaction between the P: and V: fields will be clarified when multi-voice music is addressed in abc 2.2. The use of P: for single voice music will be revisited at the same time.
  # The P: field can be used in the tune header to state the order in which the tune parts are played, i.e. P:ABABCDCD, and then inside the tune body to mark each part, i.e. P:A or P:B. (In this context part refers to a section of the tune, rather than a voice in multi-voice music.)
  # Within the tune header, you can give instruction to repeat a part by following it with a number: e.g. P:A3 is equivalent to P:AAA. You can make a sequence repeat by using parentheses: e.g. P:(AB)3 is equivalent to P:ABABAB. Nested parentheses are permitted; dots may be placed anywhere within the header P: field to increase legibility: e.g. P:((AB)3.(CD)3)2. These dots are ignored by computer programs.
  # See variant endings and lyrics for possible uses of P: notation.
  # Player programs should use the P: field if possible to render a complete playback of the tune; typesetting programs should include the P: field values in the printed score.
# See typesetting information fields for details of how the part information may be included in the printed score.

  describe "parts header field" do
    it "can be a single part" do
      p = parse_fragment "X:1\nP:A\nK:C\nabc"
      p.part_sequence.list.should == ['A']
    end
    it "can be two parts" do
      p = parse_fragment "X:1\nP:AB\nK:C\nabc"
      p.part_sequence.list.should == ['A', 'B']
    end
    it "can be one part repeating" do
      p = parse_fragment "X:1\nP:A3\nK:C\nabc"
      p.part_sequence.list.should == ['A', 'A', 'A']
    end
    it "can be two parts with one repeating" do
      p = parse_fragment "X:1\nP:A2B\nK:C\nabc"
      p.part_sequence.list.should == ['A', 'A', 'B']
    end
    it "can be two parts repeating" do
      p = parse_fragment "X:1\nP:(AB)3\nK:C\nabc"
      p.part_sequence.list.should == ['A', 'B', 'A', 'B', 'A', 'B']
    end
    it "can have nested repeats" do
      p = parse_fragment "X:1\nP:(A2B)3\nK:C\nabc"
      p.part_sequence.list.join('').should == 'AABAABAAB'
    end
    it "can contain dots anywhere" do
      p = parse_fragment "X:1\nP:.(.A.2.B.).3.\nK:C\nabc"
      p.part_sequence.list.join('').should == 'AABAABAAB'
    end
  end

  describe "parts body field" do
    it "separates parts" do
      p = parse_fragment "K:C\nP:A\nabc2\nP:B\ndefg"
      p.parts['A'].notes.count.should == 3
      p.parts['B'].notes.count.should == 4
    end
    it "works as an inline field" do
      p = parse_fragment "[P:A]abc2[P:B]defg"
      p.parts['A'].notes.count.should == 3
      p.parts['B'].notes.count.should == 4
    end
  end

  describe "next_parts method" do
    it "works" do
      p = parse_fragment "P:BA2\nK:C\n[P:A]abc2[P:B]defg"
      p.next_part.should == p.parts['B']
      p.next_part.should == p.parts['A']
      p.next_part.should == p.parts['A']
      p.next_part.should == nil
      p.part_sequence.reset
      p.next_part.should == p.parts['B']
    end
  end

  # TODO think about how parts works with voices, and esp what about voice overlays, measures etc


  # 3.1.10 Z: - transcription
  # Typically the Z: field contains the name(s) of the person(s) who transcribed the tune into abc, and possibly some contact information, e.g. an (e-)mail address or homepage URL.
  # Example: Simple transcription notes.
  # Z:John Smith, <j.s@mail.com>
  # However, it has also taken over the role of the %%abc-copyright and %%abc-edited-by since they have been deprecated (see outdated directives).
  # Example: Detailed transcription notes.
  # Z:abc-transcription John Smith, <j.s@mail.com>, 1st Jan 2010
  # Z:abc-edited-by Fred Bloggs, <f.b@mail.com>, 31st Dec 2010
  # Z:abc-copyright &copy; John Smith
  # This new usage means that an update history can be recorded in collections which are collaboratively edited by a number of users.
  # Note that there is no formal syntax for the contents of this field, although users are strongly encouraged to be consistent, but, by convention, Z:abc-copyright refers to the copyright of the abc transcription rather than the tune.
  # See typesetting information fields for details of how the transcription information may be included in the printed score.
  # Comment: If required, software may even choose to interpret specific Z: strings, for example to print out the string which follows after Z:abc-copyright.

  describe "Z: (transcription) field" do
    it "can appear in the tune header" do
      p = parse_fragment "Z:abc-copyright &copy; John Smith"
      p.transcription.should == "abc-copyright &copy; John Smith"
    end
    it "can appear in the file header" do
      p = parse "Z:abc-copyright &copy; John Smith\n\nX:1\nT:\nK:C"
      p.transcription.should == "abc-copyright &copy; John Smith"
    end
  end


end

