# -*- coding: utf-8 -*-

# TODO fields should be objects not nodes
# TODO get rid of label: on fields
# TODO change item.is_a?(Field) and item.label.text_value == 'K' to 
#    item.is_a?(Field, :type => :key)

require 'polyglot'
require 'treetop'

$LOAD_PATH.unshift File.expand_path('../lib')
require 'abc/parser'
include ABC


describe "abc 2.1:" do

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
      p.items[4].pitch.height.should == 21 # a
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
      p.header.value('J').should == 'unknown field'
    end
    it "can have an unrecognized identifier in the tune header" do
      p = parse "X:1\nT:T\nJ:unknown field\nK:C"
      p.tunes[0].header.value('J').should == 'unknown field'
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
    it "can't appear in the tune body" do
      fail_to_parse_fragment "K:C\nZ:abc-copyright &copy; John Smith\nabc"
    end
    # TODO specific support for abc-copyright and abc-edited-by
  end


  # 3.1.11 N: - notes
  # Contains general annotations, such as references to other tunes which are similar, details on how the original notation of the tune was converted to abc, etc.
  # See typesetting information fields for details of how notes may be included in the printed score.

  describe "N: (notes) field" do
    it "can appear in the tune header" do
      p = parse_fragment "N:notes are called notations"
      p.notations.should == "notes are called notations"
    end
    it "can appear in the file header" do
      p = parse "N:notes are called notations\n\nX:1\nT:\nK:C"
      p.notations.should == "notes are called notations"
    end
    it "can appear in the tune body" do
      p = parse_fragment "abc\nN:notes are called notations\ndef"
      p.items[3].value.should == "notes are called notations"
    end
    it "can appear as an inline field" do
      p = parse_fragment "abc[N:notes are called notations]def"
      p.items[3].value.should == "notes are called notations"
    end
  end


  # 3.1.12 G: - group
  # Database software may use this field to group together tunes (for example by instruments) for indexing purposes. It can also be used for creating medleys - however, this usage is not standardised.

  describe "G: (group) field" do
    it "can appear in the tune header" do
      p = parse_fragment "G:group"
      p.group.should == "group"
    end
    it "can appear in the file header" do
      p = parse "G:group\n\nX:1\nT:\nK:C"
      p.group.should == "group"
    end
    it "can't appear in the tune body" do
      fail_to_parse_fragment "abc\nG:group\ndef"
    end
    it "can't appear as an inline field" do
      fail_to_parse_fragment "abc[G:group]def"
    end
  end


  # 3.1.13 H: - history
  # Designed for multi-line notes, stories and anecdotes.
  # Although the H: fields are typically not typeset, the correct usage for multi-line input is to use field continuation syntax (+:), rather than H: at the start of each subsequent line of a multi-line note. This allows, for example, database applications to distinguish between two different anecdotes.
  # Examples:
  # H:this is considered
  # +:as a single entry
  # H:this usage is considered as two entries
  # H:rather than one
  # The original usage of H: (where subsequent lines need no field indicator) is now deprecated (see outdated information field syntax).
  # See typesetting information fields for details of how the history may be included in the printed score.

  describe "H: (history) field" do
    it "can appear in the tune header" do
      p = parse_fragment "H:history"
      p.history.should == "history"
    end
    it "can appear in the file header" do
      p = parse "H:history\n\nX:1\nT:\nK:C"
      p.history.should == "history"
    end
    it "can't appear in the tune body" do
      fail_to_parse_fragment "abc\nH:history\ndef"
    end
     it "can't appear as an inline field" do
      fail_to_parse_fragment "abc[H:history]def"
    end
    it "differentiates between continuation and separate anecdotes" do 
      p = parse_fragment "H:this is considered\n+:as a single entry\nH:this usage is considered as two entries\nH:rather than one"
      p.history.should == ["this is considered as a single entry", "this usage is considered as two entries", "rather than one"]
    end
  end


  # 3.1.14 K: - key
  # The key signature should be specified with a capital letter (A-G) which may be followed by a # or b for sharp or flat respectively. In addition the mode should be specified (when no mode is indicated, major is assumed).
  # For example, K:C major, K:A minor, K:C ionian, K:A aeolian, K:G mixolydian, K:D dorian, K:E phrygian, K:F lydian and K:B locrian would all produce a staff with no sharps or flats. The spaces can be left out, capitalisation is ignored for the modes and in fact only the first three letters of each mode are parsed so that, for example, K:F# mixolydian is the same as K:F#Mix or even K:F#MIX. As a special case, minor may be abbreviated to m.
  # This table sums up how the same key signatures can be written in different ways:

  # Mode	 Ionian	 Aeolian	 Mixolydian	 Dorian	 Phrygian	 Lydian	 Locrian
  # Key Signature	 Major	 Minor					
  # 7 sharps	C#	A#m	G#Mix	D#Dor	E#Phr	F#Lyd	B#Loc
  # 6 sharps	F#	D#m	C#Mix	G#Dor	A#Phr	BLyd	E#Loc
  # 5 sharps	B	G#m	F#Mix	C#Dor	D#Phr	ELyd	A#Loc
  # 4 sharps	E	C#m	BMix	F#Dor	G#Phr	ALyd	D#Loc
  # 3 sharps	A	F#m	EMix	BDor	C#Phr	DLyd	G#Loc
  # 2 sharps	D	Bm	AMix	EDor	F#Phr	GLyd	C#Loc
  # 1 sharp	G	Em	DMix	ADor	BPhr	CLyd	F#Loc
  # 0 sharps/flats	C	Am	GMix	DDor	EPhr	FLyd	BLoc
  # 1 flat	F	Dm	CMix	GDor	APhr	BbLyd	ELoc
  # 2 flats	Bb	Gm	FMix	CDor	DPhr	EbLyd	ALoc
  # 3 flats	Eb	Cm	BbMix	FDor	GPhr	AbLyd	DLoc
  # 4 flats	Ab	Fm	EbMix	BbDor	CPhr	DbLyd	GLoc
  # 5 flats	Db	Bbm	AbMix	EbDor	FPhr	GbLyd	CLoc
  # 6 flats	Gb	Ebm	DbMix	AbDor	BbPhr	CbLyd	FLoc
  # 7 flats	Cb	Abm	GbMix	DbDor	EbPhr	FbLyd	BbLoc

  # By specifying an empty K: field, or K:none, it is possible to use no key signature at all.
  # The key signatures may be modified by adding accidentals, according to the format K:<tonic> <mode> <accidentals>. For example, K:D Phr ^f would give a key signature with two flats and one sharp, which designates a very common mode in Klezmer (Ahavoh Rabboh) and in Arabic music (Maqam Hedjaz). Likewise, "K:D maj =c" or "K:D =c" will give a key signature with F sharp and c natural (the D mixolydian mode). Note that there can be several modifying accidentals, separated by spaces, each beginning with an accidental sign (__, _, =, ^ or ^^), followed by a note letter. The case of the letter is used to determine on which line the accidental is placed.
  # It is possible to use the format K:<tonic> exp <accidentals> to explicitly define all the accidentals of a key signature. Thus K:D Phr ^f could also be notated as K:D exp _b _e ^f, where 'exp' is an abbreviation of 'explicit'. Again, the case of the letter is used to determine on which line the accidental is placed.
  # Software that does not support explicit key signatures should mark the individual notes in the tune with the accidentals that apply to them.
  # Scottish highland pipes typically have the scale G A B ^c d e ^f g a and highland pipe music primarily uses the modes D major and A mixolyian (plus B minor and E dorian). Therefore there are two additional keys specifically for notating highland bagpipe tunes; K:HP doesn't put a key signature on the music, as is common with many tune books of this music, while K:Hp marks the stave with F sharp, C sharp and G natural. Both force all the beams and stems of normal notes to go downwards, and of grace notes to go upwards.
  # By default, the abc tune will be typeset with a treble clef. You can add special clef specifiers to the K: field, with or without a key signature, to change the clef and various other staff properties, such as transposition. K: clef=bass, for example, would indicate the bass clef. See clefs and transposition for full details.
  # Note that the first occurrence of the K: field, which must appear in every tune, finishes the tune header. All following lines are considered to be part of the tune body.

  describe "K: (key) field" do
    it "can be a simple letter" do
      p = parse_fragment "K:D"
      p.key.tonic.should == "D"
    end
    it "can have a flat in the tonic" do
      p = parse_fragment "K:Eb"
      p.key.tonic.should == "Eb"
    end
    it "can have a sharp in the tonic" do
      p = parse_fragment "K:F#"
      p.key.tonic.should == "F#"
    end
    it "defaults to major mode" do
      p = parse_fragment "K:D"
      p.key.mode.should == "major"
    end
    it "recognizes maj as major" do
      p = parse_fragment "K:D maj"
      p.key.mode.should == "major"
    end
    it "recognizes m as minor" do
      p = parse_fragment "K:Dm"
      p.key.mode.should == "minor"
    end
    it "recognizes min as minor" do
      p = parse_fragment "K:D min"
      p.key.mode.should == "minor"
    end
    it "recognizes mixolydian" do
      p = parse_fragment "K:D mix"
      p.key.mode.should == "mixolydian"
    end
    it "recognizes dorian" do
      p = parse_fragment "K:D dor"
      p.key.mode.should == "dorian"
    end
    it "recognizes locrian" do
      p = parse_fragment "K:D loc"
      p.key.mode.should == "locrian"
    end
    it "recognizes phrygian" do
      p = parse_fragment "K:D phrygian"
      p.key.mode.should == "phrygian"
    end
    it "recognizes lydian" do
      p = parse_fragment "K:D lydian"
      p.key.mode.should == "lydian"
    end
    it "recognizes aeolian" do
      p = parse_fragment "K:D loc"
      p.key.mode.should == "locrian"
    end
    it "recognizes ionian" do
      p = parse_fragment "K:D ion"
      p.key.mode.should == "ionian"
    end
    it "ignores all but the first 3 letters of the mode" do
      p = parse_fragment "K:D mixdkafjeaadkfafipqinv"
      p.key.mode.should == "mixolydian"
    end
    it "ignores capitalization of the mode" do
      p = parse_fragment "K:D Mix"
      p.key.mode.should == "mixolydian"
      p = parse_fragment "K:DMIX"
      p.key.mode.should == "mixolydian"
      p = parse_fragment "K:DmIX"
      p.key.mode.should == "mixolydian"
    end
    it "delivers accidentals for major key" do
      p = parse_fragment "K:Eb"
      sig = p.key.signature
      sig.should include 'A' => -1, 'B' => -1, 'E' => -1
      sig.should_not include 'C', 'D', 'F', 'G'
    end
    it "delivers accidentals for key with mode" do
      p = parse_fragment "K:A# Phr"
      sig = p.key.signature
      sig.should include 'C' => 1, 'D' => 1, 'E' => 1, 'F' => 1, 'G' => 1, 'A' => 1
      sig.should_not include 'B'
    end
    it "can take extra accidentals" do
      p = parse_fragment "K:Ebminor=e^c"
      p.key.extra_accidentals.should include 'E' => 0, 'C' => 1
    end
    it "delivers accidentals for key with extra accidentals" do
      p = parse_fragment "K:F =b ^C"
      sig = p.key.signature
      sig.should include 'C' => 1
      sig.should_not include %w{D E F G A B}
    end
    it "allows explicitly defined signatures" do
      p = parse_fragment "K:D exp _b _e ^f"
      p.key.tonic.should == "D"
      p.key.mode.should == nil
      p.key.signature.should == {'B' => -1, 'E' => -1, 'F' => 1}
    end
    # TODO case of the accidental determines on which line the accidental should be drawn
    it "allows K:none" do
      p = parse_fragment "K:none"
      p.key.tonic.should == nil
      p.key.mode.should == nil
      p.key.signature.should == {}
    end
    it "uses signature C#, F#, G natural for highland pipes" do
      p = parse_fragment "K:HP"
      p.key.highland_pipes?.should == true
      p.key.tonic.should == nil
      p.key.signature.should == {'C'=> 1, 'F' => 1, 'G' => 0}
      p = parse_fragment "K:Hp"
      p.key.highland_pipes?.should == true
      p.key.tonic.should == nil
      p.key.signature.should == {'C'=> 1, 'F' => 1, 'G' => 0}
    end
    it "will not show accidentals for K:HP" do
      p = parse_fragment "K:HP"
      p.key.show_accidentals?.should == false
    end
    it "will show accidentals for K:Hp" do
      p = parse_fragment "K:Hp"
      p.key.show_accidentals?.should == true
    end
  end


  # 3.1.15 R: - rhythm
  # Contains an indication of the type of tune (e.g. hornpipe, double jig, single jig, 48-bar polka, etc). This gives the musician some indication of how a tune should be interpreted as well as being useful for database applications (see background information). It has also been used experimentally by playback software (in particular, abcmus) to provide more realistic playback by altering the stress on particular notes within a bar.
  # See typesetting information fields for details of how the rhythm may be included in the printed score.

  describe "R: (rhythm) field" do
    it "can appear in the tune header" do
      p = parse_fragment "R:rhythm"
      p.rhythm.should == "rhythm"
    end
    it "can appear in the file header" do
      p = parse "R:rhythm\n\nX:1\nT:\nK:C"
      p.rhythm.should == "rhythm"
    end
    it "can appear in the tune body" do
      p = parse_fragment "abc\nR:rhythm\ndef"
      p.items[3].value.should == "rhythm"
    end
    it "can appear as an inline field" do
      p = parse_fragment "abc[R:rhythm]def"
      p.items[3].value.should == "rhythm"
    end
  end


  # 3.1.16 B:, D:, F:, S: - background information
  # The information fields B:book (i.e. printed tune book), D:discography (i.e. a CD or LP where the tune can be heard), F:file url (i.e. where the either the abc tune or the abc file can be found on the web) and S:source (i.e. the circumstances under which a tune was collected or learned), as well as the fields H:history, N:notes, O:origin and R:rhythm mentioned above, are used for providing structured background information about a tune. These are particularly aimed at large tune collections (common in abc since its inception) and, if used in a systematic way, mean that abc database software can sort, search and filter on specific fields (for example, to sort by rhythm or filter out all the tunes on a particular CD).
  # The abc standard does not prescribe how these fields should be used, but it is typical to employ several fields of the same type each containing one piece of information, rather than one field containing several pieces of information (see English.abc for some examples).
  # See typesetting information fields for details of how background information may be included in the printed score.

  describe "B: (book) field" do
    it "can appear in the tune header" do
      p = parse_fragment "B:book"
      p.book.should == "book"
    end
    it "can appear in the file header" do
      p = parse "B:book\n\nX:1\nT:\nK:C"
      p.book.should == "book"
    end
    it "can't appear in the tune body" do
      fail_to_parse_fragment "abc\nB:book\ndef"
    end
    it "can't appear as an inline field" do
      fail_to_parse_fragment "abc[B:book]def"
    end
  end

  describe "D: (discography) field" do
    it "can appear in the tune header" do
      p = parse_fragment "D:discography"
      p.discography.should == "discography"
    end
    it "can appear in the file header" do
      p = parse "D:discography\n\nX:1\nT:\nK:C"
      p.discography.should == "discography"
    end
    it "can't appear in the tune body" do
      fail_to_parse_fragment "abc\nD:discography\ndef"
    end
    it "can't appear as an inline field" do
      fail_to_parse_fragment "abc[D:discography]def"
    end
  end

  describe "F: (file url) field" do
    it "can appear in the tune header" do
      p = parse_fragment "F:file url"
      p.url.should == "file url"
    end
    it "can appear in the file header" do
      p = parse "F:file url\n\nX:1\nT:\nK:C"
      p.url.should == "file url"
    end
    it "can't appear in the tune body" do
      fail_to_parse_fragment "abc\nF:file url\ndef"
    end
    it "can't appear as an inline field" do
      fail_to_parse_fragment "abc[F:file url]def"
    end
  end

  describe "S: (source) field" do
    it "can appear in the tune header" do
      p = parse_fragment "S:source"
      p.source.should == "source"
    end
    it "can appear in the file header" do
      p = parse "S:source\n\nX:1\nT:\nK:C"
      p.source.should == "source"
    end
    it "can't appear in the tune body" do
      fail_to_parse_fragment "abc\nS:source\ndef"
    end
    it "can't appear as an inline field" do
      fail_to_parse_fragment "abc[S:source]def"
    end
  end


  # 3.1.17 I: - instruction
  # The I:(instruction) field is used for an extended set of instruction directives concerned with how the abc code is to be interpreted.
  # The I: field can be used interchangeably with stylesheet directives so that any I:directive may instead be written %%directive, and vice-versa. However, to use the inline version, the I: version must be used.
  # Despite this interchangeability, certain directives have been adopted as part of the standard (indicated by I: in this document) and must be implemented by software confirming to this version of the standard; conversely, the stylesheet directives (indicated by %% in this document) are optional.
  # Comment: Since stylesheet directives are optional, and not necessarily portable from one program to another, this means that I: fields containing stylesheet directives should be treated liberally by abc software and, in particular, that I: fields which are not recognised should be ignored.
  # The following table contains a list of the I: field directives adopted as part of the abc standard, with links to further information:

  # directive	     section
  # I:abc-charset    charset field
  # I:abc-version    version field
  # I:abc-include    include field
  # I:abc-creator    creator field
  # I:linebreak      typesetting line breaks
  # I:decoration     decoration dialects

  # Typically, instruction fields are for use in the file header, to set defaults for the file, or (in most cases) in the tune header, but not in the tune body. The occurrence of an instruction field in a tune header overrides that in the file header.
  # Comment: Remember that abc software which extracts separate tunes from a file must insert the fields of the original file header into the header of the extracted tune: this is also true for the fields defined in this section.

  describe "I: (instruction) field" do
    it "can appear in the tune header" do
      p = parse_fragment "I:name value"
      p.instructions['name'].should == "value"
    end
    it "can appear in the file header" do
      p = parse "I:name value\n\nX:1\nT:\nK:C"
      p.instructions['name'].should == "value"
    end
    it "can appear in the tune body" do
      p = parse_fragment "abc\nI:name value\ndef"
      p.items[3].name.should == "name"
      p.items[3].value.should == "value"
    end
    it "can appear as an inline field" do
      p = parse_fragment "abc[I:name value]def"
      p.items[3].name.should == "name"
      p.items[3].value.should == "value"
    end
  end


  # Charset field
  # The I:abc-charset <value> field indicates the character set in which text strings are coded. Since this affects how the file is read, it should appear as early as possible in the file header. It may not be changed further on in the file.
  # Example:
  # I:abc-charset utf-8
  # Legal values for the charset field are iso-8859-1 through to iso-8859-10, us-ascii and utf-8 (the default).
  # Software that exports abc tunes conforming to this standard should include a charset field if an encoding other than utf-8 is used. All conforming abc software must be able to handle text strings coded in utf-8 and us-ascii. Support for the other charsets is optional.
  # Extensive information about UTF-8 and ISO-8859 can be found on wikipedia.

  describe "I:abc-charset utf-8" do
    it "can't appear in the tune header" do
      fail_to_parse_fragment "I:abc-charset utf-8"
    end
    it "can appear in the file header" do
      p = parse "I:abc-charset utf-8\n\nX:1\nT:\nK:C"
      p.instructions['abc-charset'].should == "utf-8"
    end
    it "can't appear in the tune body" do
      fail_to_parse_fragment "abc\nI:abc-charset utf-8\ndef"
    end
    it "can't appear as an inline field" do
      fail_to_parse_fragment "abc[I:abc-charset utf-8]def"
    end
  end


  # Version field
  # Every abc file conforming to this standard should start with the line
  # %abc-2.1
  # (see abc file identification).
  # However to indicate tunes conforming to a different standard it is possible to use the I:abc-version <value> field, either in the tune header (for individual tunes) or in the file header.
  # Example:
  # I:abc-version 2.0

  describe "I:abc-version instruction" do
    it "can appear in the tune header" do
      p = parse_fragment "I:abc-version 2.0"
      p.instructions['abc-version'].should == "2.0"
    end
    it "can appear in the file header" do
      p = parse "I:abc-version 2.0\n\nX:1\nT:\nK:C"
      p.instructions['abc-version'].should == "2.0"
    end
    it "can't appear in the tune body" do
      fail_to_parse_fragment "abc\nI:abc-version 2.0\ndef"
    end
    it "can't appear as an inline field" do
      fail_to_parse_fragment "abc[I:abc-version 2.0]def"
    end
  end


  # Include field
  # The I:abc-include <filename.abh> imports the definitions found in a separate abc header file (.abh), and inserts them into the file header or tune header.
  # Example:
  # I:abc-include mydefs.abh
  # The included file may contain information fields, stylesheet directives and comments, but no other abc constructs.
  # If the header file cannot be found, the I:abc-include instruction should be ignored with a non-fatal error message.
  # Comment: If you use this construct and distribute your abc files, make sure that you distribute the .abh files with them.

  describe "I:abc-include instruction" do
    before do
      @filename = "test-include.abh"
      IO.write(@filename, "C:Bach")
    end

    after do
      File.delete(@filename)
    end

    it "can appear in the tune header" do
      p = parse_fragment "I:abc-include #{@filename}\nK:C"
      p.composer.should == 'Bach'
    end
    it "can appear in the file header" do
      p = parse "I:abc-include #{@filename}\n\nX:1\nT:\nK:C"
      p.composer.should == 'Bach'
    end
    it "can't appear in the tune body" do
      fail_to_parse_fragment "abc\nI:abc-include #{@filename}\ndef"
    end
    it "can't appear as an inline field" do
      fail_to_parse_fragment "abc[I:abc-include #{@filename}]def"
    end
    it "ignores whiespace at the end of the include file" do
      IO.write(@filename, "C:Bach\n\n\n   \n     ")
      p = parse_fragment "I:abc-include #{@filename}\nK:C"
      p.composer.should == 'Bach'
    end
  end


  # Creator field
  # The I:abc-creator <value> field contains the name and version number of the program that created the abc file.
  # Example:
  # I:abc-creator xml2abc-2.7
  # Software that exports abc tunes conforming to this standard must include a creator field.


  # 3.2 Use of fields within the tune body
  # It is often desired to change the key (K), meter (M), or unit note length (L) mid-tune. These, and most other information fields which can be legally used within the tune body, can be specified as an inline field by placing them within square brackets in a line of music
  # Example: The following two excerpts are considered equivalent - either variant is equally acceptable.
  # E2E EFE|E2E EFG|[M:9/8] A2G F2E D2|]
  # E2E EFE|E2E EFG|\
  # M:9/8
  # A2G F2E D2|]
  # The first bracket, field identifier and colon must be written without intervening spaces. Only one field may be placed within a pair of brackets; however, multiple bracketed fields may be placed next to each other. Where appropriate, inline fields (especially clef changes) can be used in the middle of a beam without breaking it.
  # See information fields for a table showing the fields that may appear within the body and those that may be used inline.

  # ^^ already covered


  # 3.3 Field continuation
  # A field that is too long for one line may be continued by prefixing +: at the start of the following line. For string-type information fields (see the information fields table for a list of string-type fields), the continuation is considered to add a space between the two half lines.
  # Example: The following two excerpts are considered equivalent.
  #   w:Sa-ys my au-l' wan to your aul' wan,
  #   +:will~ye come to the Wa-x-ies dar-gle?
  #   w:Sa-ys my au-l' wan to your aul' wan, will~ye come to the Wa-x-ies dar-gle?
  # Comment: This is most useful for continuing long w:(aligned lyrics) and H:(history) fields. However, it can also be useful for preventing automatic wrapping by email software (see continuation of input lines).
  # Recommendation for GUI developers: Sometimes users may wish to paste paragraphs of text into an abc file, particularly in the H:(history) field. GUI developers are recommended to provide tools for reformatting such paragraphs, for example by splitting them into several lines each prefixed by +:.
  # There is no limit to the number of times a field may be continued and comments and stylesheet directives may be interspersed between the continuations.
  # Example: The following is a legal continuation of the w: field, although the usage not recommended (the change of font could also be achieved by font specifiers - see font directives).
  #   %%vocalfont Times-Roman 14
  #   w:nor-mal
  #   % legal, but not recommended
  #   %%vocalfont Times-Italic *
  #   +:i-ta-lic
  #   %%vocalfont Times-Roman *
  #   +:nor-mal
  # Comment: abc standard 2.3 is scheduled to address markup and will be seeking a more elegant way to achieve the above.

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
      p = parse_fragment "GCEA\ns:**\n+:*!f!"
      p.notes[3].decorations[0].symbol.should == "f"
    end
    it "combines more than two lines" do
      p = parse_fragment "H:let me tell\n+:you a little\n+:about \n+:this song"
      p.history.should == "let me tell you a little about this song"
    end
    it "works across end comments" do
      p = parse_fragment "H:let me tell you a little %comment\n+:about this song"
      p.history.should == "let me tell you a little about this song"
    end
    it "works across comment lines" do
      p = parse_fragment "H:let me tell you a little \n%comment\n+:about this song"
      p.history.should == "let me tell you a little about this song"
    end
    it "works across stylesheet directives" do
      p = parse_fragment ["abcd abc",
                          "%%vocalfont Times-Roman 14",
                          "w:nor-mal",
                          "% legal, but not recommended",
                          "%%vocalfont Times-Italic *",
                          "+:i-ta-lic",
                          "%%vocalfont Times-Roman 14",
                          "+:nor-mal"].join("\n")
      p.lines[0].lyrics_lines[0].units.map {|u| u.text }.join("").should == "normalitalicnormal"
      # TODO make it easier to recover lyrics
    end
  end


  # 4. The tune body

  # 4.1 Pitch
  # The following letters are used to represent notes using the treble clef:
  #                                                       d'
  #                                                 -c'- ----
  #                                              b
  #                                         -a- --- ---- ----
  #                                        g
  #  ------------------------------------f-------------------
  #                                    e
  #  --------------------------------d-----------------------
  #                                c
  #  ----------------------------B---------------------------
  #                            A
  #  ------------------------G-------------------------------
  #                        F
  #  --------------------E-----------------------------------
  #                    D
  #  ---- ---- ---- -C-
  #             B,
  #  ---- -A,-
  #   G,
  # and by extension other lower and higher notes are available.
  # Lower octaves are reached by using commas and higher octaves are written using apostrophes; each extra comma/apostrophe lowers/raises the note by an octave.
  # Programs should be able to to parse any combinations of , and ' signs appearing after the note. For example C,', (C comma apostrophe comma) has the the same meaning as C, (C comma) and (uppercase) C' (C apostrophe) should have the same meaning as (lowercase) c.
  # Alternatively, it is possible to raise or lower a section of music code using the octave parameter of the K: or V: fields.
  # Comment: The English note names C-B, which are used in the abc system, correspond to the note names do-si, which are used in many other languages: do=C, re=D, mi=E, fa=F, sol=G, la=A, si=B.

  describe "a pitch specifier" do
    it "indicates the middle-c octave with capital letters" do
      p = parse_fragment "CDEFGAB"
      p.notes.each do |note| 
        note.pitch.octave.should == 0
        note.pitch.height.should == note.pitch.height_in_octave
      end
      p.notes[0].pitch.height.should == 0
      p.notes[1].pitch.height.should == 2
      p.notes[2].pitch.height.should == 4
      p.notes[3].pitch.height.should == 5
      p.notes[4].pitch.height.should == 7
      p.notes[5].pitch.height.should == 9
      p.notes[6].pitch.height.should == 11
    end
    it "indicates octave 1 with lowercase letters" do
      p = parse_fragment "cdefgab"
      p.notes.each do |note| 
        note.pitch.octave.should == 1
        note.pitch.height.should == note.pitch.height_in_octave + 12
      end
      p.notes[0].pitch.height.should == 12
      p.notes[1].pitch.height.should == 14
      p.notes[2].pitch.height.should == 16
      p.notes[3].pitch.height.should == 17
      p.notes[4].pitch.height.should == 19
      p.notes[5].pitch.height.should == 21
      p.notes[6].pitch.height.should == 23
    end
    it "indicates higher octaves with apostrophes" do
      p = parse_fragment "C'c'''"
      p.notes[0].pitch.octave.should == 1
      p.notes[1].pitch.octave.should == 4
    end
    it "indicates lower octave down with commas" do
      p = parse_fragment "C,,,,c,,"
      p.notes[0].pitch.octave.should == -4
      p.notes[1].pitch.octave.should == -1
    end
    it "can use any combination of commas and apostrophes" do
      p = parse_fragment "C,',',,c,,'''',"
      p.notes[0].pitch.octave.should == -2
      p.notes[1].pitch.octave.should == 2
    end
    # TODO make this work when we get to clef
    it "can be octave-shifted by the K: field" do
       p = parse_fragment "[K:treble-8]C"
       p.notes[0].pitch.octave.should == -1
    end
    it "can be octave-shifted by the K: field in the header" do
       p = parse_fragment "K:treble-8\nC"
       p.notes[0].pitch.octave.should == -1
    end
    it "can be octave-shifted by the K: field inline" do
       p = parse_fragment "[K:treble-8]C"
       p.notes[0].pitch.octave.should == -1
    end
    it "can be octave-shifted by the V: field" do
       p = parse_fragment "V:1 treble+8\nK:C\n[V:1]C"
       p.voices['1'].notes[0].pitch.octave.should == 1
    end
    it "will not have its octave-shift canceled by a K: field with no clef" do
       p = parse_fragment "V:1 treble+8\nK:C\n[V:1][K:D]C"
       p.voices['1'].notes[0].pitch.clef.should == p.voices['1'].clef
       p.voices['1'].notes[0].pitch.octave.should == 1
    end
    it "will use the tune's clef if the voice doesn't specify one" do
       p = parse_fragment "K:treble+8\n[V:1]C"
       p.voices['1'].notes[0].pitch.clef.should == p.clef
       p.voices['1'].notes[0].pitch.octave.should == 1
    end
  end
  

  # 4.2 Accidentals
  # The symbols ^, = and _ are used (before a note) to notate respectively a sharp, natural or flat. Double sharps and flats are available with ^^ and __ respectively.

  describe "an accidental specifier" do
    it "can be applied to any note" do
      parse_fragment "^A ^^a2 _b/ __C =D"
    end
    it "cannot take on bizarro forms" do
      fail_to_parse_fragment "^_A"
      fail_to_parse_fragment "_^A"
      fail_to_parse_fragment "^^^A"
      fail_to_parse_fragment "=^A"
      fail_to_parse_fragment "___A"
      fail_to_parse_fragment "=_A"
    end
    it "is valued accurately" do
      p = parse_fragment "^A^^a2_b/__C=DF"
      p.notes[0].pitch.accidental.should == 1
      p.notes[1].pitch.accidental.should == 2
      p.notes[2].pitch.accidental.should == -1
      p.notes[3].pitch.accidental.should == -2
      p.notes[4].pitch.accidental.should == 0
      p.notes[5].pitch.accidental.should == nil
    end
    it "changes the height of the corresponding note" do
      p = parse_fragment "^C^^C2_C/__C=CC"
      p.notes[0].pitch.height.should == 1
      p.notes[1].pitch.height.should == 2
      p.notes[2].pitch.height.should == -1
      p.notes[3].pitch.height.should == -2
      p.notes[4].pitch.height.should == 0
      p.notes[5].pitch.height.should == 0
    end
  end


   # 4.3 Note lengths
   # Throughout this document note lengths are referred as sixteenth, eighth, etc. The equivalents common in the U.K. are sixteenth note = semi-quaver, eighth = quaver, quarter = crotchet and half = minim.
   # The unit note length for the transcription is set in the L: field or, if the L: field does not exist, inferred from the M: field. For example, L:1/8 sets an eighth note as the unit note length.
   # A single letter in the range A-G, a-g then represents a note of this length. For example, if the unit note length is an eighth note, DEF represents 3 eighth notes.
   # Notes of differing lengths can be obtained by simply putting a multiplier after the letter. Thus if the unit note length is 1/16, A or A1 is a sixteenth note, A2 an eighth note, A3 a dotted eighth note, A4 a quarter note, A6 a dotted quarter note, A7 a double dotted quarter note, A8 a half note, A12 a dotted half note, A14 a double dotted half note, A15 a triple dotted half note and so on. If the unit note length is 1/8, A is an eighth note, A2 a quarter note, A3 a dotted quarter note, A4 a half note, and so on.
   # To get shorter notes, either divide them - e.g. if A is an eighth note, A/2 is a sixteenth note, A3/2 is a dotted eighth note, A/4 is a thirty-second note - or change the unit note length with the L: field. Alternatively, if the music has a broken rhythm, e.g. dotted eighth note/sixteenth note pairs, use broken rhythm markers.
   # Note that A/ is shorthand for A/2 and similarly A// = A/4, etc.
   # Comment: Note lengths that can't be translated to conventional staff notation are legal, but their representation by abc typesetting software is undefined and they should be avoided.
   # Note for developers: All compliant software should be able to handle note lengths down to a 128th note; shorter lengths are optional.

  describe "note length specifier" do
    it "cannot be bizarre" do
      fail_to_parse_fragment "a//4"
      fail_to_parse_fragment "a3//4"
    end
    it "defaults to 1" do
      p = parse_fragment "L:1\na"
      p.notes[0].note_length.should == 1
    end
    it "can be an integer multiplier" do
      p = parse_fragment "L:1\na3"
      p.notes[0].note_length.should == 3
    end
    it "can be a simple fraction" do
      p = parse_fragment "L:1\na3/2"
      p.notes[0].note_length.should == Rational(3,2)
    end
    it "can be slashes" do
      p = parse_fragment "L:1\na///"
      p.notes[0].note_length.should == Rational(1, 8)
    end
    it "is relative to the default unit note length" do
      p = parse_fragment "ab2c3/2d3/e/" # default unit note length 1/8
      p.notes[0].note_length.should == Rational(1, 8)
      p.notes[1].note_length.should == Rational(1, 4)
      p.notes[2].note_length.should == Rational(3, 16)
      p.notes[3].note_length.should == Rational(3, 16)
      p.notes[4].note_length.should == Rational(1, 16)
    end
    it "is relative to an explicit unit note length" do
      p = parse_fragment "L:1/2\nab2c3/2d3/e/"
      tune = p
      tune.notes[0].note_length.should == Rational(1, 2)
      tune.notes[1].note_length.should == 1
      tune.notes[2].note_length.should == Rational(3, 4)
      tune.notes[3].note_length.should == Rational(3, 4)
      tune.notes[4].note_length.should == Rational(1, 4)
    end
     it "is relative to a new unit note length after an L: field in the tune body" do
      p = parse_fragment "L:1/2\na4\nL:1/4\na4"
      tune = p
      tune.notes[0].note_length.should == 2
      tune.notes[1].note_length.should == 1
    end
    it "is relative to a new unit note length after an inline L: field" do
      p = parse_fragment "L:1/2\na4[L:1/4]a4"
      tune = p
      tune.notes[0].note_length.should == 2
      tune.notes[1].note_length.should == 1
    end
  end


   # 4.4 Broken rhythm
   # A common occurrence in traditional music is the use of a dotted or broken rhythm. For example, hornpipes, strathspeys and certain morris jigs all have dotted eighth notes followed by sixteenth notes, as well as vice-versa in the case of strathspeys. To support this, abc notation uses a > to mean 'the previous note is dotted, the next note halved' and < to mean 'the previous note is halved, the next dotted'.
   # Example: The following lines all mean the same thing (the third version is recommended):
   # L:1/16
   # a3b cd3 a2b2c2d2
   # L:1/8
   # a3/2b/2 c/2d3/2 abcd
   # L:1/8
   # a>b c<d abcd
   # As a logical extension, >> means that the first note is double dotted and the second quartered and >>> means that the first note is triple dotted and the length of the second divided by eight. Similarly for << and <<<.
   # Note that the use of broken rhythm markers between notes of unequal lengths will produce undefined results, and should be avoided.

  describe "a broken rhythm marker" do
    it "is allowed" do
      parse_fragment "a>b c<d a>>b c2<<d2"
    end
    it "cannot be immediately followed by another one in the other direction" do
      fail_to_parse_fragment "a<>b"
      fail_to_parse_fragment "a><b"
    end
    it "appears as an attribute of the following note" do
      p = parse_fragment "a>b"
      p.items[0].broken_rhythm_marker.should == nil
      p.items[1].broken_rhythm_marker.change('>').should == Rational(1, 2)
    end
    it "alters note lengths appropriately" do
      tune = parse_fragment "L:1\na>b c<d e<<f g>>>a"
      tune.items[0].note_length.should == Rational(3, 2)
      tune.items[1].note_length.should == Rational(1, 2)
      tune.items[2].note_length.should == Rational(1, 2)
      tune.items[3].note_length.should == Rational(3, 2)
      tune.items[4].note_length.should == Rational(1, 4)
      tune.items[5].note_length.should == Rational(7, 4)
      tune.items[6].note_length.should == Rational(15, 8)
      tune.items[7].note_length.should == Rational(1, 8)
    end
    it "works with the default unit note length" do
      p = parse_fragment "a>b"
      p.items[0].note_length.should == Rational(3, 16)
      p.items[1].note_length.should == Rational(1, 16)
    end
    it "works with note length specifiers" do
      p = parse_fragment "a2>b2"
      p.items[0].note_length.should == Rational(3, 8)
      p.items[1].note_length.should == Rational(1, 8)
    end
  end


  # 4.5 Rests
  # Rests can be transcribed with a z or an x and can be modified in length in exactly the same way as normal notes. z rests are printed in the resulting sheet music, while x rests are invisible, that is, not shown in the printed music.
  # Multi-measure rests are notated using Z (upper case) followed by the number of measures.
  # Example: The following excerpts, shown with the typeset results, are musically equivalent (although they are typeset differently).
  # Z4|CD EF|GA Bc
  # z4|z4|z4|z4|CD EF|GA Bc
  # When the number of measures is not given, Z is equivalent to a pause of one measure.
  # By extension multi-measure invisible rests are notated using X (upper case) followed by the number of measures and when the number of measures is not given, X is equivalent to a pause of one measure.
  # Comment: Although not particularly valuable, a multi-measure invisible rest could be useful when a voice is silent for several measures.

  describe "a visible rest (z)" do
    it "can appear with a length specifier" do
      p = parse_fragment "L:1\n z3/2 z//"
      p.items[0].length.should == Rational(3, 2)
      p.items[1].length.should == Rational(1, 4)
    end
    it "cannot have a bizarro length specifier" do
      fail_to_parse_fragment "z3//4"
    end
    it "knows it's visible" do
      p = parse_fragment "z"
      p.items[0].invisible?.should == false
    end
  end
  
  describe "an invisible rest (x)" do
    it "can appear with a length specifier" do
      p = parse_fragment "L:1\n x3/2 x//"
      p.items[0].length.should == Rational(3, 2)
      p.items[1].length.should == Rational(1, 4)
    end
    it "cannot have a bizarro length specifier" do
      fail_to_parse_fragment "x3//4"
    end
    it "knows it's invisible" do
      p = parse_fragment "x"
      p.items[0].invisible?.should == true
    end
  end

  describe "a visible measure rest (Z)" do
    it "knows its measure count" do
      p = parse_fragment "Z4"
      p.items[0].measure_count.should == 4
    end
    it "can calculate its note length based on the meter" do
      p = parse_fragment "M:C\nZ4[M:3/4]Z2\n"
      p.items[0].length.should == 4
      p.items[2].length.should == Rational(6, 4)
    end
    it "defaults to one measure" do
      p = parse_fragment "Z"
      p.items[0].measure_count.should == 1
    end
    it "knows it's visible" do
      p = parse_fragment "Z"
      p.items[0].invisible?.should == false
    end
  end

  describe "an invisible measure rest (X)" do
    it "knows its measure count" do
      p = parse_fragment "X4"
      p.items[0].measure_count.should == 4
    end
    it "can calculate its note length based on the meter" do
      p = parse_fragment "M:C\nX4[M:3/4]X2\n"
      p.items[0].length.should == 4
      p.items[2].length.should == Rational(6, 4)
    end
    it "defaults to one measure" do
      p = parse_fragment "X"
      p.items[0].measure_count.should == 1
    end
    it "knows it's invisible" do
      p = parse_fragment "X"
      p.items[0].invisible?.should == true
    end
  end


  # 4.6 Clefs and transposition
  # VOLATILE: This section is subject to some clarifications with regard to transposition, rules for the middle parameter and interactions between different parameters.
  # Clef and transposition information may be provided in the K: key and V: voice fields. The general syntax is:
  # [clef=]<clef name>[<line number>][+8 | -8] [middle=<pitch>] [transpose=<semitones>] [octave=<number>] [stafflines=<lines>]
  # (where <…> denotes a value, […] denotes an optional parameter, and | separates alternative values).
  # <clef name> - may be treble, alto, tenor, bass, perc or none. perc selects the drum clef. clef= may be omitted.
  # [<line number>] - indicates on which staff line the base clef is written. Defaults are: treble: 2; alto: 3; tenor: 4; bass: 4.
  # [+8 | -8] - draws '8' above or below the staff. The player will transpose the notes one octave higher or lower.
  # [middle=<pitch>] - is an alternate way to define the line number of the clef. The pitch indicates what note is displayed on the 3rd line of the staff. Defaults are: treble: B; alto: C; tenor: A,; bass: D,; none: B.
  # [transpose=<semitones>] - for playback, transpose the current voice by the indicated amount of semitones; positive numbers transpose up, negative down. This setting does not affect the printed score. The default is 0.
  # [octave=<number>] to raise (positive number) or lower (negative number) the music code in the current voice by one or more octaves. This usage can help to avoid the need to write lots of apostrophes or commas to raise or lower notes.
  # [stafflines=<lines>] - the number of lines in the staff. The default is 5.
  # Note that the clef, middle, transpose, octave and stafflines specifiers may be used independent of each other.
  # Examples:
  #   K:   clef=alto
  #   K:   perc stafflines=1
  #   K:Am transpose=-2
  #   V:B  middle=d bass
  # Note that although this standard supports the drum clef, there is currently no support for special percussion notes.
  # The middle specifier can be handy when working in the bass clef. Setting K:bass middle=d will save you from adding comma specifiers to the notes. The specifier may be abbreviated to m=.
  # The transpose specifier is useful, for example, for a Bb clarinet, for which the music is written in the key of C although the instrument plays it in the key of Bb:
  #   V:Clarinet
  #   K:C transpose=-2
  # The transpose specifier may be abbreviated to t=.
  # To notate the various standard clefs, one can use the following specifiers:
  # The seven clefs

  # Name          specifier
  # Treble        K:treble
  # Bass          K:bass
  # Baritone      K:bass3
  # Tenor         K:tenor
  # Alto          K:alto
  # Mezzosoprano  K:alto2
  # Soprano       K:alto1

  # More clef names may be allowed in the future, therefore unknown names should be ignored. If the clef is unknown or not specified, the default is treble.
  # Applications may introduce their own clef line specifiers. These specifiers should start with the name of the application, followed a colon, followed by the name of the specifier.
  # Example:
  # V:p1 perc stafflines=3 m=C  mozart:noteC=snare-drum

  describe "a clef specifier" do
    it "can appear in a K: field" do
      p = parse_fragment "K:Am clef=bass"
      p.clef.name.should == "bass"
    end
    it "can appear in a V: field" do
      p = parse_fragment "V:Bass clef=bass"
      p.voices["Bass"].clef.name.should == "bass"
    end
    it "can appear without 'clef='" do
      p = parse_fragment "K:bass"
      p.clef.name.should == "bass"
    end
    it "can have names treble, alto, tenor, bass, perc or none" do
      p = parse_fragment "K:treble"
      p.key.clef.name.should == "treble"
      p = parse_fragment "K:alto"
      p.key.clef.name.should == "alto"
      p = parse_fragment "K:tenor"
      p.key.clef.name.should == "tenor"
      p = parse_fragment "K:bass"
      p.key.clef.name.should == "bass"
      p = parse_fragment "K:perc"
      p.key.clef.name.should == "perc"
      p = parse_fragment "K:clef=none"
      p.key.clef.name.should == "none"
    end
    it "can specify the line on which to draw the clef" do
      p = parse_fragment "K:Am clef=bass4"
      p.key.clef.line.should == 4
    end
    it "has default lines for the basic clefs" do
      p = parse_fragment "K:C clef=treble"
      p.key.clef.line.should == 2
      p = parse_fragment "K:C clef=alto"
      p.key.clef.line.should == 3
      p = parse_fragment "K:C clef=tenor"
      p.key.clef.line.should == 4
      p = parse_fragment "K:C clef=bass"
      p.key.clef.line.should == 4
    end
    it "can include a 1-octave shift up or down using +8 or -8" do
      p = parse_fragment "K:Am clef=bass"
      p.key.clef.octave_shift.should == 0
      p = parse_fragment "K:Am clef=alto+8"
      p.key.clef.octave_shift.should == 1
      p = parse_fragment "K:Am clef=treble-8"
      p.key.clef.octave_shift.should == -1
    end    
    it "can specify a middle pitch" do
      p = parse_fragment "K:C clef=treble middle=d"
      p.key.clef.middle.height.should == 14
      p = parse_fragment "K:C treble middle=d"
      p.key.clef.middle.height.should == 14
      p = parse_fragment "K:C middle=d"
      p.key.clef.middle.height.should == 14
    end
    it "has default middle pitch for the basic clefs" do
      p = parse_fragment "K:C clef=treble"
      p.key.clef.middle.height.should == 11
      p = parse_fragment "K:C clef=alto"
      p.key.clef.middle.height.should == 0
      p = parse_fragment "K:C clef=tenor"
      p.key.clef.middle.height.should == -3
      p = parse_fragment "K:C clef=bass"
      p.key.clef.middle.height.should == -10
      p = parse_fragment "K:C clef=none"
      p.key.clef.middle.height.should == 11
    end
    it "can specify a transposition" do
      p = parse_fragment "K:C clef=treble transpose=-2"
      p.key.clef.transpose.should == -2
      p = parse_fragment "K:C clef=treble t=4"
      p.key.clef.transpose.should == 4
    end
    it "has a default transposition of 0" do
      p = parse_fragment "K:C clef=treble"
      p.key.clef.transpose.should == 0
    end
    it "can specify an octave shift with 'octave='" do
      p = parse_fragment "K:C clef=treble octave=-2\nc"
      p.key.clef.octave_shift.should == -2
      p.notes[0].pitch.height.should == -12
    end
    it "has a default octave shift of 0" do
      p = parse_fragment "K:C clef=treble"
      p.key.clef.octave_shift.should == 0
    end
    it "can specify the number of stafflines" do
      p = parse_fragment "K:C clef=treble stafflines=4"
      p.key.clef.stafflines.should == 4
    end
    it "has a default of 5 stafflines" do
      p = parse_fragment "K:C clef=treble"
      p.key.clef.stafflines.should == 5
    end
    it "is allowed to use unknown clef names" do
      p = parse_fragment "K:C baritone"
      p.key.clef.name.should == 'baritone' 
    end
    it "matches treble clef's line and middle pitch if clef name is unknown" do
      p = parse_fragment "K:C baritone"
      p.key.clef.line.should == 2
      p.key.clef.middle.height.should == 11
    end
    it "defaults to treble" do
      p = parse_fragment "K:C"
      p.key.clef.name.should == 'treble'
    end
    it "is allowed to use app-specific specifiers" do
      p = parse_fragment "K:C clef=perc mozart:noteC=snare-drum"
    end
    it "can place its specifiers in any order" do
      p = parse_fragment "K:C middle=d stafflines=3 bass4+8 t=-3"
      p.clef.name.should == 'bass'
      p.clef.middle.note.should == 'D'
      p.clef.stafflines.should == 3
      p.clef.transpose.should == -3
      p.clef.octave_shift.should == 1
    end
    it "can combine octave shifts with octave= and +/-8" do
      p = parse_fragment "K: bass+8 octave=-1"
      p.clef.octave_shift.should == 0
    end
  end


    # 4.7 Beams
    # To group notes together under one beam they must be grouped together without spaces. Thus in 2/4, A2BC will produce an eighth note followed by two sixteenth notes under one beam whilst A2 B C will produce the same notes separated. The beam slopes and the choice of upper or lower stems are typeset automatically.
    # Notes that cannot be beamed may be placed next to each other. For example, if L:1/8 then ABC2DE is equivalent to AB C2 DE.
    # Back quotes ` may be used freely between notes to be beamed, to increase legibility. They are ignored by computer programs. For example, A2``B``C is equivalent to A2BC.

  describe "a beam" do
    it "connects adjacent notes" do
      p = parse_fragment "abc"
      p.items[0].beam.should == :start
      p.items[1].beam.should == :middle
      p.items[2].beam.should == :end
    end
    it "connects notes separated by backticks" do
      p = parse_fragment "a``b"
      p.items[0].beam.should == :start
      p.items[1].beam.should == :end
    end
    it "does not connect notes separated by space" do
      p = parse_fragment "ab c"
      p.notes[1].beam.should == :end
      p.notes[2].beam.should == nil
    end
    it "does not connect notes separated by bar lines" do
      p = parse_fragment "ab|c"
      p.notes[1].beam.should == :end
      p.notes[2].beam.should == nil
    end
    it "does not connect notes separated by fields" do
      p = parse_fragment "ab[L:1/16]c"
      p.notes[1].beam.should == :end
    end
    it "connects notes separated by line continuation" do
      p = parse_fragment "ab\\\nc"
      p.notes[1].beam.should == :middle
      p.notes[2].beam.should == :end
    end
    it "does not connect notes separated by space plus line continuation" do
      p = parse_fragment "ab \\\nc"
      p.notes[1].beam.should == :end
      p.notes[2].beam.should == nil
    end
    it "does not connect notes separated by line continuation plus space" do
      p = parse_fragment "ab\\\n c"
      p.notes[1].beam.should == :end
      p.notes[2].beam.should == nil
    end
    it "does not connect notes that are unbeamable" do
      p = parse_fragment "ab2"
      p.notes[0].beam.should == nil
      p.notes[1].beam.should == nil
    end
    it "does not connect notes separated by overlay symbols" do
      p = parse_fragment "a&b"
      p.notes[0].beam.should == nil
      p.notes[1].beam.should == nil
    end
    it "does not connect notes separated by rests" do
      p = parse_fragment "axb"
      p.notes[0].beam.should == nil
      p.notes[1].beam.should == nil
    end
  end


  # 4.8 Repeat/bar symbols
  # Bar line symbols are notated as follows:
  # |	  bar line
  # |]  thin-thick double bar line
  # ||  thin-thin double bar line
  # [|  thick-thin double bar line
  # |:  start of repeated section
  # :|  end of repeated section
  # ::  start & end of two repeated sections
  # Recommendation for developers: If an 'end of repeated section' is found without a previous 'start of repeated section', playback programs should restart the music from the beginning of the tune, or from the latest double bar line or end of repeated section.
    # Note that the notation :: is short for :| followed by |:. The variants ::, :|: and :||: are all equivalent.
    # By extension, |:: and ::| mean the start and end of a section that is to be repeated three times, and so on.
    # A dotted bar line can be notated by preceding it with a dot, e.g. .| - this may be useful for notating editorial bar lines in music with very long measures.
    # An invisible bar line may be notated by putting the bar line in brackets, e.g. [|] - this may be useful for notating voice overlay in meter-free music.
    # Abc parsers should be quite liberal in recognizing bar lines. In the wild, bar lines may have any shape, using a sequence of | (thin bar line), [ or ] (thick bar line), and : (dots), e.g. |[| or [|::: .

  describe "a bar line" do
    
    it "can be thin" do
      p = parse_fragment "a|b"
      bar = p.items[1]
      bar.is_a?(BarLine).should == true
      bar.type.should == :thin
    end
    it "can be double" do
      p = parse_fragment "a||b"
      p.items.count.should == 3
      bar = p.items[1]
      bar.is_a?(BarLine).should == true
      bar.type.should == :double
    end
    it "can be thin-thick" do
      p = parse_fragment "a|]"
      p.items.count.should == 2
      bar = p.items.last
      bar.is_a?(BarLine).should == true
      bar.type.should == :thin_thick
    end
    it "can be thick-thin" do
      p = parse_fragment "[|C"
      p.items.count.should == 2
      bar = p.items[0]
      bar.is_a?(BarLine).should == true
      bar.type.should == :thick_thin
    end
    it "can be dotted" do
      p = parse_fragment "a.|b"
      p.items.count.should == 3
      bar = p.items[1]
      bar.is_a?(BarLine).should == true
      bar.dotted?.should == true
    end
    it "can be invisible" do
      p = parse_fragment "a[|]b"
      p.items.count.should == 3
      bar = p.items[1]
      bar.is_a?(BarLine).should == true
      bar.type.should == :invisible
    end
    it "can repeat to the left" do
      p = parse_fragment "|:"
      p.items[0].type.should == :thin
      p.items[0].repeat_before.should == 0
      p.items[0].repeat_after.should == 1
    end
    it "can repeat to the right" do
      p = parse_fragment ":|"
      p.items[0].type.should == :thin
      p.items[0].repeat_before.should == 1
      p.items[0].repeat_after.should == 0
    end    
    it "can repeat to the right if it's thin-thick" do
      p = parse_fragment ":|]"
      p.items[0].type.should == :thin_thick
      p.items[0].repeat_before.should == 1
      p.items[0].repeat_after.should == 0
    end
    it "can repeat to the left if it's thin-thick" do
      p = parse_fragment "[|:"
      p.items[0].type.should == :thick_thin
      p.items[0].repeat_before.should == 0
      p.items[0].repeat_after.should == 1
    end
    it "can indicate multiple repeats" do
      p = parse_fragment "::|"
      p.items[0].repeat_before.should == 2
      p.items[0].repeat_after.should == 0
    end
  end


  # 4.9 First and second repeats
  # First and second repeats can be notated with the symbols [1 and [2, e.g.
  #   faf gfe|[1 dfe dBA:|[2 d2e dcB|].
  # When adjacent to bar lines, these can be shortened to |1 and :|2, but with regard to spaces
  #   | [1
  # is legal, while
  #   | 1
  # is not.
  # Thus, a tune with different ending for the first and second repeats has the general form:
  #   |:  <common body of tune>  |1  <first ending>  :|2  <second ending>  |]
  # Note that in many abc files the |: may not be present.

  describe "first and second ending" do
    it "can be notated with [1 and [2" do
      p = parse_fragment "abc|[1 abc :|[2 def |]"
      p.items[4].is_a?(VariantEnding).should == true
      p.items[4].range_list.should == [1]
      p.items[9].is_a?(VariantEnding).should == true
      p.items[9].range_list.should == [2]
    end
    it "can be notated with |1 and |2" do 
      p = parse_fragment "abc|1 abc:|2 def ||"
      p.items[4].is_a?(VariantEnding).should == true
      p.items[4].range_list.should == [1]
      p.items[9].is_a?(VariantEnding).should == true
      p.items[9].range_list.should == [2]
    end
    it "can be notated with | [1" do
      p = parse_fragment "abc| [1 abc :| [2 def |]"
      p.items[4].is_a?(VariantEnding).should == true
      p.items[4].range_list.should == [1]
      p.items[9].is_a?(VariantEnding).should == true
      p.items[9].range_list.should == [2]
    end
    it "cannot be notated with | 1" do 
      fail_to_parse_fragment "abc| 1 abc:|2 def |]"
    end
  end


    # 4.10 Variant endings
    # In combination with P: part notation, it is possible to notate more than two variant endings for a section that is to be repeated a number of times.
    # For example, if the header of the tune contains P:A4.B4 then parts A and B will each be played 4 times. To play a different ending each time, you could write in the tune:
    #   P:A
    #   <notes> | [1  <notes>  :| [2 <notes> :| [3 <notes> :| [4 <notes> |]
    # The Nth ending starts with [N and ends with one of ||, :| |] or [|. You can also mark a section as being used for more than one ending e.g.
    #   [1,3 <notes> :|
    # plays on the 1st and 3rd endings and
    #   [1-3 <notes> :|
    # plays on endings 1, 2 and 3. In general, '[' can be followed by any list of numbers and ranges as long as it contains no spaces e.g.
    #   [1,3,5-7  <notes>  :| [2,4,8 <notes> :|
  
  describe "a variant ending" do
    it "can involve a range list" do
      p = parse_fragment "[1,3,5-7 abc || [2,4,8 def ||"
      p.items[0].range_list.should == [1, 3, 5..7]
      p.items[5].range_list.should == [2, 4, 8]
    end
  end


    # 4.11 Ties and slurs
    # You can tie two notes of the same pitch together, within or between bars, with a - symbol, e.g. abc-|cba or c4-c4. The tie symbol must always be adjacent to the first note of the pair, but does not need to be adjacent to the second, e.g. c4 -c4 and abc|-cba are not legal - see order of abc constructs.
    # More general slurs can be put in with () symbols. Thus (DEFG) puts a slur over the four notes. Spaces within a slur are OK, e.g. ( D E F G ) .
    # Slurs may be nested:
    # (c (d e f) g a)
    # and they may also start and end on the same note:
    # (c d (e) f g a)
    # A dotted slur may be notated by preceding the opening brace with a dot, e.g. .(cde); it is optional to place a dot immediately before the closing brace. Likewise, a dotted tie can be transcribed by preceding it with a dot, e.g. C.-C. This is especially useful in parts with multiple verses: some verses may require a slur, some may not.
    # It should be noted that although the tie - and slur () produce similar symbols in staff notation they have completely different meanings to player programs and should not be interchanged. Ties connect two successive notes of the same pitch, causing them to be played as a single note, while slurs connect the first and last note of any series of notes, and may be used to indicate phrasing, or that the group should be played legato. Both ties and slurs may be used into, out of and between chords, and in this case the distinction between them is particularly important.

  describe "a tie" do
    it "does not appear by default" do
      p = parse_fragment "a a"
      p.items[0].tied_right.should == false
      p.items[1].tied_left.should == false
    end
    it "is indicated by a hyphen" do
      p = parse_fragment "a-a"
      p.items[0].tied_right.should == true
      p.items[1].tied_left.should == true
    end
    # TODO convert this to slur
    it "can be used to mark a slur" do
      p = parse_fragment "a-b"
      p.items[0].tied_right.should == true
      p.items[1].tied_left.should == true
    end
    it "can operate across spaces" do
      p = parse_fragment "a- b"
      p.items[0].tied_right.should == true
      p.items[1].tied_left.should == true
    end
    it "can operate across bar lines" do
      p = parse_fragment "a-|b"
      p.items[0].tied_right.should == true
      p.items[2].tied_left.should == true
    end
    it "can operate across fields" do
      p = parse_fragment "a-[M:6/8]b"
      p.items[0].tied_right.should == true
      p.items[2].tied_left.should == true
    end
    it "can be dotted" do
      p = parse_fragment "a.-b"
      p.items[0].tied_right.should == false
      p.items[0].tied_right_dotted.should == true
      p.items[1].tied_left.should == true
    end
  end

  describe "a slur" do
    it "is indicated with parenthesis" do
      p = parse_fragment "d(ab^c)d"
      p.items[1].start_slur.should == 1
      p.items[3].end_slur.should == 1
    end
    it "can be nested" do
      p = parse_fragment "d(a(b^c))"
      p.items[1].start_slur.should == 1
      p.items[2].start_slur.should == 1
      p.items[3].end_slur.should == 2
    end
    it "can exist on a single note" do
      p = parse_fragment "d(a)b^c"
      p.items[1].start_slur.should == 1
      p.items[1].end_slur.should == 1
    end
    it "can operate across spaces" do
      p = parse_fragment "(a b c)"
      p.items[0].start_slur.should == 1
      p.items[2].end_slur.should == 1
    end
    it "can operate across bar lines" do
      p = parse_fragment "(ab|c)"
      p.items[0].start_slur.should == 1
      p.items[3].end_slur.should == 1
    end
    it "can operate across fields" do
      p = parse_fragment "(ab[M:6/8]c)"
      p.items[0].start_slur.should == 1
      p.items[3].end_slur.should == 1
    end
    it "can slur a single note" do
      p = parse_fragment "(a)"
      p.items[0].start_slur.should == 1
      p.items[0].end_slur.should == 1
    end
    it "can be dotted" do
      p = parse_fragment "(a.(bc))"
      p.notes[0].start_slur.should == 1
      p.notes[0].start_dotted_slur.should == 0
      p.notes[1].start_slur.should == 0
      p.notes[1].start_dotted_slur.should == 1
      p.notes[2].end_slur.should == 2
    end
  end


    # 4.12 Grace notes
    # Grace notes can be written by enclosing them in curly braces, {}. For example, a taorluath on the Highland pipes would be written {GdGe}. The tune 'Athol Brose' (in the file Strspys.abc) has an example of complex Highland pipe gracing in all its glory. Although nominally grace notes have no melodic time value, expressions such as {a3/2b/} or {a>b} can be useful and are legal although some software may ignore them. The unit duration to use for gracenotes is not specified by the abc file, but by the software, and might be a specific amount of time (for playback purposes) or a note length (e.g. 1/32 for Highland pipe music, which would allow {ge4d} to code a piobaireachd 'cadence').
    # To distinguish between appoggiaturas and acciaccaturas, the latter are notated with a forward slash immediately following the open brace, e.g. {/g}C or {/gagab}C:
    # The presence of gracenotes is transparent to the broken rhythm construct. Thus the forms A<{g}A and A{g}<A are legal and equivalent to A/2{g}A3/2.

  describe "a grace note marker" do
    it "can indicate an appogiatura" do
      p = parse_fragment "{gege}B"
      p.notes[0].grace_notes.type.should == :appoggiatura
    end
    it "can indicate an acciaccatura" do
      p = parse_fragment "{/ge4d}B"
      p.notes[0].grace_notes.type.should == :acciaccatura
    end
    it "has notes" do
      p = parse_fragment "{gege}B"
      p.notes[0].grace_notes.notes.count.should == 4
      p.notes[0].grace_notes.notes[0].pitch.note.should == "G"
    end
    it "applies the current key to the notes" do
      p = parse_fragment "[K:HP]{gf}B"
      p.notes[0].grace_notes.notes[1].pitch.height.should == 18 # F sharp
    end
    it "can include note length markers" do
      p = parse_fragment "{a3/2b/}B"
    end
    it "is independent of the unit note length" do
      p = parse_fragment "{a3/2b/}B"
      p.notes[0].length.should == Rational(1, 8)
      p.notes[0].grace_notes.notes[0].length.should == Rational(3, 2)
      p.notes[0].grace_notes.notes[1].length.should == Rational(1, 2)
    end
    it "can include broken rhythm markers" do
      p = parse_fragment "{a>b}B"
      p.notes[0].grace_notes.notes[0].length.should == Rational(3, 2)
      p.notes[0].grace_notes.notes[1].length.should == Rational(1, 2)
    end
    it "is transparent to the broken rhythm construct" do
      p = parse_fragment "B{ab}>A"
      p.notes[0].length.should == Rational(3, 16)
      p.notes[1].length.should == Rational(1, 16)
      p.notes[0].grace_notes.should == nil
      p.notes[1].grace_notes.notes.count.should == 2
    end
  end


  # 4.13 Duplets, triplets, quadruplets, etc.
  # These can be simply coded with the notation (2ab for a duplet, (3abc for a triplet or (4abcd for a quadruplet, etc, up to (9. The musical meanings are:
  # Symbol	Meaning
  # (2	 2 notes in the time of 3
  # (3	 3 notes in the time of 2
  # (4	 4 notes in the time of 3
  # (5	 5 notes in the time of n
  # (6	 6 notes in the time of 2
  # (7	 7 notes in the time of n
  # (8	 8 notes in the time of 3
  # (9	 9 notes in the time of n
  # If the time signature is compound (6/8, 9/8, 12/8) then n is three, otherwise n is two.
  # More general tuplets can be specified using the syntax (p:q:r which means 'put p notes into the time of q for the next r notes'. If q is not given, it defaults as above. If r is not given, it defaults to p.
  # For example, (3 is equivalent to (3:: or (3:2 , which in turn are equivalent to (3:2:3, whereas (3::2 is equivalent to (3:2:2.
  # This can be useful to include notes of different lengths within a tuplet, for example (3:2:2 G4c2 or (3:2:4 G2A2Bc. It also describes more precisely how the simple syntax works in cases like (3 D2E2F2 or even (3 D3EF2. The number written over the tuplet is p.
  # Spaces that appear between the tuplet specifier and the following notes are to be ignored.
  
  describe "a tuplet marker" do
    it "uses (2 to mean 2 notes in the time of 3, regardless of meter" do
      p = parse_fragment "[L:1] [M:C] (2abc [M:3/4] (2abc"
      p.notes[0].tuplet_ratio.should == Rational(3, 2)
      p.notes[0].length.should == Rational(3, 2)
      p.notes[1].length.should == Rational(3, 2)
      p.notes[2].length.should == 1
      p.notes[3].length.should == Rational(3, 2)
      p.notes[4].length.should == Rational(3, 2)
      p.notes[5].length.should == 1
    end

    it "can be inspected" do
      p = parse_fragment "[L:1] [M:C] (2abc [M:3/4] (2abc"
      marker = p.notes[0].tuplet_marker
      marker.compound_meter?.should be_false
      marker.ratio.should == Rational(3, 2)
      marker.num_notes.should == 2
      marker.number_to_print.should == 2
      p.notes[1].tuplet_marker.should == nil
      marker = p.notes[3].tuplet_marker
      marker.compound_meter.should == true
      marker.ratio.should == Rational(3, 2)
      marker.num_notes.should == 2
      marker.number_to_print.should == 2
    end

    it "conspires with the unit note length to determine note length" do
      p = parse_fragment "[L:1/8] (2abc [L:1/4] (2abc"
      p.notes[0].tuplet_ratio.should == Rational(3, 2)
      p.notes[0].length.should == Rational(3, 16)
      p.notes[1].length.should == Rational(3, 16)
      p.notes[2].length.should == Rational(1, 8)
      p.notes[3].tuplet_ratio.should == Rational(3, 2)
      p.notes[3].length.should == Rational(3, 8)
      p.notes[4].length.should == Rational(3, 8)
      p.notes[5].length.should == Rational(1, 4)
    end
      
    it "uses (3 to mean 3 notes in the time of 2, regardless of meter" do
      p = parse_fragment "[L:1] [M:C] (3abcd [M:3/4] (3abcd"
      p.notes[0].length.should == Rational(2, 3)
      p.notes[1].length.should == Rational(2, 3)
      p.notes[2].length.should == Rational(2, 3)
      p.notes[3].length.should == 1
      p.notes[4].length.should == Rational(2, 3)
      p.notes[5].length.should == Rational(2, 3)
      p.notes[6].length.should == Rational(2, 3)
      p.notes[7].length.should == 1
    end
    
    it "uses (4 to mean 4 notes in the time of 3, regardless of meter" do
      p = parse_fragment "[L:1] [M:C] (4abcde [M:3/4] (4abcde"
      p.notes[0].length.should == Rational(3, 4)
      p.notes[1].length.should == Rational(3, 4)
      p.notes[2].length.should == Rational(3, 4)
      p.notes[3].length.should == Rational(3, 4)
      p.notes[4].length.should == 1
      p.notes[5].length.should == Rational(3, 4)
      p.notes[6].length.should == Rational(3, 4)
      p.notes[7].length.should == Rational(3, 4)
      p.notes[8].length.should == Rational(3, 4)
      p.notes[9].length.should == 1
    end
    
    it "uses (5 to mean 5 notes in the time of 2, if meter is simple" do
      p = parse_fragment "[L:1] [M:C] (5abcdef"
      p.notes[0].length.should == Rational(2, 5)
      p.notes[1].length.should == Rational(2, 5)
      p.notes[2].length.should == Rational(2, 5)
      p.notes[3].length.should == Rational(2, 5)
      p.notes[4].length.should == Rational(2, 5)
      p.notes[5].length.should == 1
    end
    
    it "uses (5 to mean 5 notes in the time of 3, if meter is compound" do
      p = parse_fragment "[L:1] [M:6/8] (5abcdef"
      p.notes[0].length.should == Rational(3, 5)
      p.notes[1].length.should == Rational(3, 5)
      p.notes[2].length.should == Rational(3, 5)
      p.notes[3].length.should == Rational(3, 5)
      p.notes[4].length.should == Rational(3, 5)
      p.notes[5].length.should == 1
    end

    it "uses (6 to mean 6 notes in the time of 2" do
      p = parse_fragment "[L:1] [M:C] (6 abc abc d [M:6/8] (6 abc abc d"
      p.notes[5].length.should == Rational(2, 6)
      p.notes[6].length.should == 1
      p.notes[12].length.should == Rational(2, 6)
      p.notes[13].length.should == 1
    end

    it "uses (6 to mean 6 notes in the time of 2" do
      p = parse_fragment "[L:1] [M:C] (6 abc abc d [M:6/8] (6 abc abc d"
      p.notes[5].length.should == Rational(2, 6)
      p.notes[6].length.should == 1
      p.notes[12].length.should == Rational(2, 6)
      p.notes[13].length.should == 1
    end
    
    it "uses (7 to mean 7 notes in the time of 2 (or 3 for compound meter)" do
      p = parse_fragment "[L:1] [M:C] (7 abcd abc d [M:6/8] (7 abcd abc d"
      p.notes[6].length.should == Rational(2, 7)
      p.notes[7].length.should == 1
      p.notes[14].length.should == Rational(3, 7)
      p.notes[15].length.should == 1
    end
    
    it "uses (8 to mean 8 notes in the time of 3" do
      p = parse_fragment "[L:1] [M:C] (8 abcd abcd e [M:6/8] (8 abcd abcd e"
      p.notes[7].length.should == Rational(3, 8)
      p.notes[8].length.should == 1
      p.notes[16].length.should == Rational(3, 8)
      p.notes[17].length.should == 1
    end
    
    it "uses (9 to mean 9 notes in the time of 2 (or 3 for compound meter)" do
      p = parse_fragment "[L:1] [M:C] (9 abcde abcd e [M:6/8] (9 abcde abcd e"
      p.notes[8].length.should == Rational(2, 9)
      p.notes[9].length.should == 1
      p.notes[18].length.should == Rational(3, 9)
      p.notes[19].length.should == 1
    end
    
    it "uses the form (p:q:r to mean p notes in the time of q for r notes" do
      p = parse_fragment "[L:1] (3:4:6 abc abc d"
      p.notes[5].length.should == Rational(4, 3)
      p.notes[6].length.should == 1
    end

    it "uses the form (p:q to mean p notes in the time of q for p notes" do
      p = parse_fragment "[L:1] (3:4 abc d"
      p.notes[2].length.should == Rational(4, 3)
      p.notes[3].length.should == 1
    end

    it "treats the form (p:q: as a synonym for (p:q" do
      p = parse_fragment "[L:1] (3:4: abc d"
      p.notes[2].length.should == Rational(4, 3)
      p.notes[3].length.should == 1
    end

    it "uses the form (p::r to mean p notes in the time of 2 for r notes with simple meter" do
      p = parse_fragment "[L:1] [M:C] (3::4 abcd e"
      p.notes[3].length.should == Rational(2, 3)
      p.notes[4].length.should == 1
    end

    it "uses the form (p::r to mean p notes in the time of 2 for r notes with compound meter" do
      p = parse_fragment "[L:1] [M:6/8] (2::4 abcd e"
      p.notes[3].length.should == Rational(3, 2)
      p.notes[4].length.should == 1
    end

    it "treats the form (p:: as a synonym for (p" do
      p = parse_fragment "[L:1] [M:C] (5:: abcde f [M:6/8] (5:: abcde f"
      p.notes[4].length.should == Rational(2, 5)
      p.notes[5].length.should == 1
      p.notes[10].length.should == Rational(3, 5)
      p.notes[11].length.should == 1
    end

    it "treats the form (p: as a synonym for (p" do
      p = parse_fragment "[L:1] [M:C] (5: abcde f [M:6/8] (5: abcde f"
      p.notes[4].length.should == Rational(2, 5)
      p.notes[5].length.should == 1
      p.notes[10].length.should == Rational(3, 5)
      p.notes[11].length.should == 1
    end

    it "can operate on notes of different lengths" do
      p = parse_fragment "[L:1] [M:C] (3 D3EF2"
      p.notes[0].length.should == 2
      p.notes[1].length.should == Rational(2, 3)
      p.notes[2].length.should == Rational(4, 3)
    end

    # TODO generate errors if not enough notes in tuplet

  end


  # 4.14 Decorations
  # A number of shorthand decoration symbols are available:
  # .       staccato mark
  # ~       Irish roll
  # H       fermata
  # L       accent or emphasis
  # M       lowermordent
  # O       coda
  # P       uppermordent
  # S       segno
  # T       trill
  # u       up-bow
  # v       down-bow
  # Decorations should be placed before the note which they decorate - see order of abc constructs
  # Examples:
  # (3.a.b.c    % staccato triplet
  # vAuBvA      % bowing marks (for fiddlers)
  # Most of the characters above (~HLMOPSTuv) are just short-cuts for commonly used decorations and can even be redefined (see redefinable symbols).
  # More generally, symbols can be entered using the syntax !symbol!, e.g. !trill!A4 for a trill symbol. (Note that the abc standard version 2.0 used instead the syntax +symbol+ - this dialect of abc is still available, but is now deprecated - see decoration dialects.)
  # The currently defined symbols are:
  # !trill!                "tr" (trill mark)
  # !trill(!               start of an extended trill
  # !trill)!               end of an extended trill
  # !lowermordent!         short /|/|/ squiggle with a vertical line through it
  # !uppermordent!         short /|/|/ squiggle
  # !mordent!              same as !lowermordent!
  # !pralltriller!         same as !uppermordent!
  # !roll!                 a roll mark (arc) as used in Irish music
  # !turn!                 a turn mark (also known as gruppetto)
  # !turnx!                a turn mark with a line through it
  # !invertedturn!         an inverted turn mark
  # !invertedturnx!        an inverted turn mark with a line through it
  # !arpeggio!             vertical squiggle
  # !>!                    > mark
  # !accent!               same as !>!
  # !emphasis!             same as !>!
  # !fermata!              fermata or hold (arc above dot)
  # !invertedfermata!      upside down fermata
  # !tenuto!               horizontal line to indicate holding note for full duration
  # !0! - !5!              fingerings
  # !+!                    left-hand pizzicato, or rasp for French horns
  # !plus!                 same as !+!
  # !snap!                 snap-pizzicato mark, visually similar to !thumb!
  # !slide!                slide up to a note, visually similar to a half slur
  # !wedge!                small filled-in wedge mark
  # !upbow!                V mark
  # !downbow!              squared n mark
  # !open!                 small circle above note indicating open string or harmonic
  # !thumb!                cello thumb symbol
  # !breath!               a breath mark (apostrophe-like) after note
  # !pppp! !ppp! !pp! !p!  dynamics marks
  # !mp! !mf! !f! !ff!     more dynamics marks
  # !fff! !ffff! !sfz!     more dynamics marks
  # !crescendo(!           start of a < crescendo mark
  # !<(!                   same as !crescendo(!
  # !crescendo)!           end of a < crescendo mark, placed after the last note
  # !<)!                   same as !crescendo)!
  # !diminuendo(!          start of a > diminuendo mark
  # !>(!                   same as !diminuendo(!
  # !diminuendo)!          end of a > diminuendo mark, placed after the last note
  # !>)!                   same as !diminuendo)!
  # !segno!                2 ornate s-like symbols separated by a diagonal line
  # !coda!                 a ring with a cross in it
  # !D.S.!                 the letters D.S. (=Da Segno)
  # !D.C.!                 the letters D.C. (=either Da Coda or Da Capo)
  # !dacoda!               the word "Da" followed by a Coda sign
  # !dacapo!               the words "Da Capo"
  # !fine!                 the word "fine"
  # !shortphrase!          vertical line on the upper part of the staff
  # !mediumphrase!         same, but extending down to the centre line
  # !longphrase!           same, but extending 3/4 of the way down
  # Note that the decorations may be applied to notes, rests, note groups, and bar lines. If a decoration is to be typeset between notes, it may be attached to the y spacer - see typesetting extra space.
  # Spaces may be used freely between each of the symbols and the object to which it should be attached. Also an object may be preceded by multiple symbols, which should be printed one over another, each on a different line.
  # Example:
  # [!1!C!3!E!5!G]  !coda! y  !p! !trill! C   !fermata!|
  # Player programs may choose to ignore most of the symbols mentioned above, though they may be expected to implement the dynamics marks, the accent mark and the staccato dot. Default volume is equivalent to !mf!. On a scale from 0-127, the relative volumes can be roughly defined as: !pppp! = !ppp! = 30, !pp! = 45, !p! = 60, !mp! = 75, !mf! = 90, !f! = 105, !ff! = 120, !fff! = !ffff! = 127.
  # Abc software may also allow users to define new symbols in a package dependent way.
  # Note that symbol names may not contain any spaces, [, ], | or : signs, e.g. while !dacapo! is legal, !da capo! is not.
  # If an unimplemented or unknown symbol is found, it should be ignored.
  # Recommendation: A good source of general information about decorations can be found at http://www.dolmetsch.com/musicalsymbols.htm.

  describe "a decoration" do
    it "can be one of the default redefinable symbols" do
      p = parse_fragment ".a ~b Hc Ld Me Of Pg Sa Tb uC vD"
      p.notes[0].decorations[0].shortcut.should == "."
      p.notes[0].decorations[0].symbol.should == "staccato"
      p.notes[1].decorations[0].shortcut.should == "~"
      p.notes[1].decorations[0].symbol.should == "roll"
      p.notes[2].decorations[0].shortcut.should == "H"
      p.notes[2].decorations[0].symbol.should == "fermata"
      p.notes[3].decorations[0].shortcut.should == "L"
      p.notes[3].decorations[0].symbol.should == "emphasis"
      p.notes[4].decorations[0].shortcut.should == "M"
      p.notes[4].decorations[0].symbol.should == "lowermordent"
      p.notes[5].decorations[0].shortcut.should == "O"
      p.notes[5].decorations[0].symbol.should == "coda"
      p.notes[6].decorations[0].shortcut.should == "P"
      p.notes[6].decorations[0].symbol.should == "uppermordent"
      p.notes[7].decorations[0].shortcut.should == "S"
      p.notes[7].decorations[0].symbol.should == "segno"
      p.notes[8].decorations[0].shortcut.should == "T"
      p.notes[8].decorations[0].symbol.should == "trill"
      p.notes[9].decorations[0].shortcut.should == "u"
      p.notes[9].decorations[0].symbol.should == "upbow"
      p.notes[10].decorations[0].shortcut.should == "v"
      p.notes[10].decorations[0].symbol.should == "downbow"
    end
    it "can be of the form !symbol!" do
      p = parse_fragment "!trill! A"
      p.notes[0].decorations[0].symbol.should == "trill"
    end
    it "can be applied to chords" do
      p = parse_fragment "!f! [CGE]"
      p.notes[0].decorations[0].symbol.should == "f"
    end
    it "can be applied to bar lines" do
      p = parse_fragment "abc !fermata! |"
      p.items[3].decorations[0].symbol.should == "fermata"
    end
    it "can be applied to spacers" do
      p = parse_fragment "abc !fermata! y"
      p.items[3].decorations[0].symbol.should == "fermata"
    end
    it "can be one of several applied to the same note" do
      p = parse_fragment "!p! !trill! .a"
      p.notes[0].decorations.count.should == 3
      p.notes[0].decorations[0].symbol.should == "p"
      p.notes[0].decorations[1].symbol.should == "trill"
      p.notes[0].decorations[2].symbol.should == "staccato"
    end
    it "cannot include spaces" do
      fail_to_parse_fragment "!da capo! A"
    end
    it "cannot include colons" do
      fail_to_parse_fragment "!da:capo! A"
    end
    it "cannot include a vertical bar" do
      fail_to_parse_fragment "!da|capo! A"
    end
    it "cannot include square brackets" do
      fail_to_parse_fragment "![dacapo]! A"
    end
  end


  # 4.15 Symbol lines
  # Adding many symbols to a line of music can make a tune difficult to read. In such cases, a symbol line (a line that contains only !…! decorations, "…" chord symbols or annotations) can be used, analogous to a line of lyrics.
  # A symbol line starts with s:, followed by a line of symbols. Matching of notes and symbols follow the alignment rules defined for lyrics (meaning that symbols in an s: line cannot be aligned on grace notes, rests or spacers).
  # Example:
  #    CDEF    | G```AB`c
  # s: "^slow" | !f! ** !fff!
  # It is also possible to stack s: lines to produced multiple symbols on a note.
  # Example: The following two excerpts are equivalent and would place a decorations plus a chord on the E.
  #    C2  C2 Ez   A2|
  # s: "C" *  "Am" * |
  # s: *   *  !>!  * |
  # "C" C2 C2 "Am" !>! Ez A2|

  describe "a symbol line" do
    it "applies symbol line symbols to notes" do
      p = parse_fragment([     "CDEF    | G```AB`c     c",
                          "s: \"^slow\" | u ** !fff! \"Gm\""].join("\n"))
      p.lines[0].symbol_lines.count.should == 1
      p.notes[0].annotations[0].placement.should == :above
      p.notes[0].annotations[0].text.should == "slow"
      p.notes[1].annotations.should == []
      p.notes[1].decorations.should == []
      p.notes[2].decorations.should == []
      p.notes[3].decorations.should == []
      p.notes[4].decorations[0].symbol.should == 'upbow'
      p.notes[5].decorations.should == []
      p.notes[6].decorations.should == []
      p.notes[7].decorations[0].symbol.should == 'fff'
      p.notes[8].chord_symbol.text.should == 'Gm'
    end
    it "ignores dotted bar lines when skipping to next bar" do
      p = parse_fragment("abc.|de|f\ns:!f!|!f!")
      p.notes[0].decorations[0].symbol.should == "f"
      p.notes[3].decorations[0].should == nil
      p.notes[5].decorations[0].symbol.should == "f"
    end
    it "can stack symbols with consecutive symbol lines" do
      p = parse_fragment ['C2 C2 Ez A2 |', 's: "C" * "Am" * |', 's: * * !>! * |'] * "\n"
      p.notes[0].chord_symbol.text.should == "C"
      p.notes[2].chord_symbol.text.should == "Am"
      p.notes[2].decorations[0].symbol.should == ">"
    end
  end


  # 4.16 Redefinable symbols
  # As a short cut to writing symbols which avoids the !symbol! syntax (see decorations), the letters H-W and h-w and the symbol ~ can be assigned with the U: field. For example, to assign the letter T to represent the trill, you can write:
  # U: T = !trill!
  # You can also use "^text", etc (see annotations below) in definitions
  # Example: To print a plus sign over notes, define p as follows and use it before the required notes:
  # U: p = "^+"
  # Symbol definitions can be written in the file header, in which case they apply to all the tunes in that file, or in a tune header, when they apply only to that tune, and override any previous definitions. Programs may also make use of a set of global default definitions, which apply everywhere unless overridden by local definitions. You can assign the same symbol to two or more letters e.g.
  # U: T = !trill!
  # U: U = !trill!
  # in which case the same visible symbol will be produced by both letters (but they may be played differently), and you can de-assign a symbol by writing:
  # U: T = !nil!
  # or
  # U: T = !none!
  # The standard set of definitions (if you do not redefine them) is:
  # U: ~ = !roll!
  # U: H = !fermata!
  # U: L = !accent!
  # U: M = !lowermordent!
  # U: O = !coda!
  # U: P = !uppermordent!
  # U: S = !segno!
  # U: T = !trill!
  # U: u = !upbow!
  # U: v = !downbow!
  # Please see macros for an advanced macro mechanism.

  describe "a redefinable symbol" do
    it "can define a new decoration shortcut" do
      p = parse_fragment("[U:t=!halftrill!] ta")
      p.notes[0].decorations[0].symbol.should == 'halftrill'
    end
    it "can redefine one of the predefined shortcuts" do
      p = parse_fragment("[U:T=!halftrill!] Ta")
      p.notes[0].decorations[0].symbol.should == 'halftrill'
    end
    it "can define a shortcut in the tune header" do
      p = parse_fragment("U:t=!halftrill!\nK:C\nta")
      p.notes[0].decorations[0].symbol.should == 'halftrill'
    end
    it "can define a shortcut in the file header" do
      p = parse("U:t=!halftrill!\n\nX:1\nT:T\nK:C\nta")
      p.tunes[0].notes[0].decorations[0].symbol.should == 'halftrill'
    end
    it "can be redefined after being defined once" do
      p = parse("U:t=!halftrill!\n\nX:1\nT:T\nK:C\n[U:t=!headbutt!]ta")
      p.tunes[0].notes[0].decorations[0].symbol.should == 'headbutt'
      p = parse("U:t=!halftrill!\n\nX:1\nT:T\nU:t=!headbutt!\nK:C\nta")
      p.tunes[0].notes[0].decorations[0].symbol.should == 'headbutt'
    end
    it "can define annotations as well as decorations" do
      p = parse("U:t=\"^look up here\"\n\nX:1\nT:T\nK:C\nta")
      p.tunes[0].notes[0].annotations[0].text.should == 'look up here'
      p.tunes[0].notes[0].annotations[0].placement.should == :above
    end
    it "can have the same value as another" do
      p = parse("U:T=!thrill!  X:1 T:T U:U=!thrill! K:C TaUb".gsub(' ', "\n"))
      p.tunes[0].notes[0].decorations[0].symbol.should == 'thrill'
      p.tunes[0].notes[1].decorations[0].symbol.should == 'thrill'
    end
    it "can be de-assigned with !nil! or !none!" do
      p = parse_fragment(".a[U:.=!nil!].b ua[U:u=!none!]ub")
      p.notes[0].decorations[0].symbol.should == 'staccato'
      p.notes[1].decorations[0].symbol.should == nil
      p.notes[2].decorations[0].symbol.should == 'upbow'
      p.notes[3].decorations[0].symbol.should == nil
    end
  end


  # 4.17 Chords and unisons
  # Chords (i.e. more than one note head on a single stem) can be coded with [] symbols around the notes, e.g.
  # [CEGc]
  # indicates the chord of C major. They can be grouped in beams, e.g.
  # [d2f2][ce][df]
  # but there should be no spaces within the notation for a chord. See the tune 'Kitchen Girl' in the sample file Reels.abc for a simple example.
  # All the notes within a chord should normally have the same length, but if not, the chord duration is that of the first note.
  # Recommendation: Although playback programs should not have any difficulty with notes of different lengths, typesetting programs may not always be able to render the resulting chord to staff notation (for example, an eighth and a quarter note cannot be represented on the same stem) and the result is undefined. Consequently, this is not recommended.
  # More complicated chords can be transcribed with the & operator (see voice overlay).
  # The chord forms a syntactic grouping, to which the same prefixes and postfixes can be attached as to an ordinary note (except for accidentals which should be attached to individual notes within the chord and decorations which may be attached to individual notes within the chord or may be attached to the chord as a whole).
  # Example:
  # ( "^I" !f! [CEG]- > [CEG] "^IV" [F=AC]3/2"^V"[GBD]/  H[CEG]2 )
  # When both inside and outside the chord length modifiers are used, they should be multiplied. Example: [C2E2G2]3 has the same meaning as [CEG]6.
  # If the chord contains two notes of the same pitch, then it is a unison (e.g. a note played on two strings of a violin simultaneously) and is shown with one stem and two note-heads.
  # Example:
  # [DD]

  describe "a chord" do
    it "is grouped together with square brackets" do
      p = parse_fragment "[CEG]"
      p.notes[0].is_a?(Chord).should == true
      p.notes[0].notes.count.should == 3
      p.notes[0].notes[0].pitch.height.should == 0
      p.notes[0].notes[1].pitch.height.should == 4
      p.notes[0].notes[2].pitch.height.should == 7
    end
    it "can be beamed" do
      p = parse_fragment "[d2f2][ce][df] [ce]"
      p.notes[0].beam.should == nil
      p.notes[1].beam.should == :start
      p.notes[2].beam.should == :end
      p.notes[3].beam.should == nil
    end
    it "has its duration determined by the first note if notes have inconsistent lengths" do
      p = parse_fragment "[d2ag/]"
      p.notes[0].length.should == Rational(1, 4)
    end
    it "cannot take an accidental" do
      fail_to_parse_fragment "^[CEG]"
      fail_to_parse_fragment "_[CEG]"
      parse_fragment "[C_EG]"
    end
    it "can have decorations on the inside notes" do
      p = parse_fragment "[.CuE!hoohah!G]"
      p.items[0].notes[0].annotations[0] == 'staccato'
      p.items[0].notes[1].annotations[0] == 'upbow'
      p.items[0].notes[2].annotations[0] == 'hoohah'
    end
    it "multiplies inner length modifiers by outer" do
      p = parse_fragment "L:1\n[C2E2G2]3/"
      p.items[0].notes[0].length.should == 3
    end
    it "obeys key signatures" do
      p = parse_fragment "K:D\n[DFA]"
      p.items[0].notes[1].pitch.height.should == 6      
    end
    it "obeys measure accidentals" do
      p = parse_fragment "^F[DFA]|[DFA]"
      p.items[1].notes[1].pitch.height.should == 6      
      p.items[3].notes[1].pitch.height.should == 5      
    end
    it "creates measure accidentals" do
      p = parse_fragment "[D^FA]F|F"
      p.items[1].pitch.height.should == 6      
      p.items[3].pitch.height.should == 5
    end
  end


  # 4.18 Chord symbols
  # VOLATILE: The list of chords and how they are handled will be extended at some point. Until then programs should treat chord symbols quite liberally.
  # Chord symbols (e.g. chords/bass notes) can be put in under the melody line (or above, depending on the package) using double-quotation marks placed to the left of the note it is sounded with, e.g. "Am7"A2D2.
  # The chord has the format <note><accidental><type></bass>, where <note> can be A-G, the optional <accidental> can be b, #, the optional <type> is one or more of
  # m or min        minor
  # maj             major
  # dim             diminished
  # aug or +        augmented
  # sus             suspended
  # 7, 9 ...        7th, 9th, etc.
  # and </bass> is an optional bass note.
  # A slash after the chord type is used only if the optional bass note is also used, e.g., "C/E". If the bass note is a regular part of the chord, it indicates the inversion, i.e., which note of the chord is lowest in pitch. If the bass note is not a regular part of the chord, it indicates an additional note that should be sounded with the chord, below it in pitch. The bass note can be any letter (A-G or a-g), with or without a trailing accidental sign (b or #). The case of the letter used for the bass note does not affect the pitch.
  # Alternate chords can be indicated for printing purposes (but not for playback) by enclosing them in parentheses inside the double-quotation marks after the regular chord, e.g., "G(Em)".
  # Note to developers: Software should also be able to recognise and handle appropriately the unicode versions of flat, natural and sharp symbols (♭, ♮, ♯) - see special symbols.

  describe "a chord symbol" do
    it "can be attached to a note" do
      p = parse_fragment '"Am7"A2D2'
      p.items[0].chord_symbol.text.should == "Am7"
    end
    it "can include a bass note" do
      p = parse_fragment '"C/E"G'
      p.items[0].chord_symbol.text.should == "C/E"
    end
    it "can include an alternate chord" do
      p = parse_fragment '"G(Em/G)"G'
      p.items[0].chord_symbol.text.should == "G(Em/G)"
    end
    # TODO parse the chord symbols for note, type, bassnote etc
  end


  # 4.19 Annotations
  # General text annotations can be added above, below or on the staff in a similar way to chord symbols. In this case, the string within double quotes is preceded by one of five symbols ^, _, <, > or @ which controls where the annotation is to be placed; above, below, to the left or right respectively of the following note, rest or bar line. Using the @ symbol leaves the exact placing of the string to the discretion of the interpreting program. These placement specifiers distinguish annotations from chord symbols, and should prevent programs from attempting to play or transpose them. All text that follows the placement specifier is treated as a text string.
  # Where two or more annotations with the same placement specifier are placed consecutively, e.g. for fingerings, the notation program should draw them on separate lines, with the first listed at the top.
  # Example: The following annotations place the note between parentheses.
  # "<(" ">)" C

  describe "a annotationion" do
    it "can be placed above a note" do
      p = parse_fragment '"^above"c'
      p.items[0].annotations[0].placement.should == :above
      p.items[0].annotations[0].text.should == "above"
    end
    it "can be placed below a note" do
      p = parse_fragment '"_below"c'
      p.items[0].annotations[0].placement.should == :below
      p.items[0].annotations[0].text.should == "below"
    end
    it "can be placed to the left and right of a note" do
      p = parse_fragment '"<(" ">)" c'
      p.items[0].annotations[0].placement.should == :left
      p.items[0].annotations[0].text.should == "("
      p.items[0].annotations[1].placement.should == :right
      p.items[0].annotations[1].text.should == ")"
    end
    it "can have unspecified placement" do
      p = parse_fragment '"@wherever" c'
      p.items[0].annotations[0].placement.should == :unspecified
      p.items[0].annotations[0].text.should == "wherever"
    end
  end


  # 4.20 Order of abc constructs
  # The order of abc constructs for a note is: <grace notes>, <chord symbols>, <annotations>/<decorations> (e.g. Irish roll, staccato marker or up/downbow), <accidentals>, <note>, <octave>, <note length>, i.e. ~^c'3 or even "Gm7"v.=G,2.
  # Each tie symbol, -, should come immediately after a note group but may be followed by a space, i.e. =G,2- . Open and close chord delimiters, [ and ], should enclose entire note sequences (except for chord symbols), e.g.
  # "C"[CEGc]|
  # |"Gm7"[.=G,^c']
  # and open and close slur symbols, (), should do likewise, i.e.
  # "Gm7"(v.=G,2~^c'2)

  describe "order of abc constructs" do
    it "expects gracenotes before chord symbols" do
      parse_fragment '{gege}"Cmaj"C'
      fail_to_parse_fragment '"Cmaj"{gege}C'
    end
    it "expects gracenotes before decorations" do
      parse_fragment '{gege}!trill!C'
      fail_to_parse_fragment '!trill!{gege}C'
    end
    it "expects gracenotes before annotations" do
      parse_fragment '{gege}"^p"C'
      fail_to_parse_fragment '"^p"{gege}C'
    end
    it "expects chord symbols before decorations" do
      parse_fragment '"Cm"!trill!C'
      fail_to_parse_fragment '!trill!"Cm"C'
    end
    it "expects chord symbols before annotations" do
      parse_fragment '"Cm""^p"C'
      fail_to_parse_fragment '"^p""Cm"C'
    end
    it "is correct in the example fragments from the draft" do
      parse_fragment '"C"[CEGc]|'
      parse_fragment '|"Gm7"[.=G,^c\']'
    end
    # TODO support this? really?
    it "does not accept this example" do
      fail_to_parse_fragment '"Gm7"(v.=G,2~^c\'2)'
    end
  end


  # 5. Lyrics
  # The W: information field (uppercase W) can be used for lyrics to be printed separately below the tune.
  # The w: information field (lowercase w) in the tune body, supplies lyrics to be aligned syllable by syllable with previous notes of the current voice.

  describe "W: (words, unaligned) field" do
    it "can appear in the tune header" do
      p = parse_fragment "W: Da doo run run run"
      p.unaligned_lyrics.should == "Da doo run run run"
      p.words.should == "Da doo run run run"
    end
    it "can't appear in the file header" do
      fail_to_parse "W:doo wop she bop\n\nX:1\nT:\nK:C"
    end
    it "can appear in the tune body" do
      p = parse_fragment "abc\nW:doo wop she bop\ndef"
      p.items[3].value.should == "doo wop she bop"
    end
    it "can't appear as an inline field" do
      fail_to_parse_fragment "abc[W:doo wop she bop]def"
    end
  end


  # 5.1 Alignment
  # When adjacent, w: fields indicate different verses (see below), but for non-adjacent w: fields, the alignment of the lyrics:
  # starts at the first note of the voice if there is no previous w: field; or
  # starts at the first note after the notes aligned to the previous w: field; and
  # associates syllables to notes up to the end of the w: line.
  # Example: The following two examples are equivalent.
  # C D E F|
  # w: doh re mi fa
  # G A B c|
  # w: sol la ti doh
  # C D E F|
  # G A B c|
  # w: doh re mi fa sol la ti doh
  # Comment: The second example, made possible by an extension (introduced in abc 2.1) of the alignment rules, means that lyrics no longer have to follow immediately after the line of notes to which they are attached. Indeed, the placement of the lyrics can be postponed to the end of the tune body. However, the extension of the alignment rules is not fully backwards compatible with abc 2.0 - see outdated lyrics alignment for an explanation.
  # If there are fewer syllables than available notes, the remaining notes have no lyric (blank syllables); thus the appearance of a w: field associates all the notes that have appeared previously with a syllable (either real or blank).
  # Example: In the following example the empty w: field means that the 4 G notes have no lyric associated with them.
  # C D E F|
  # w: doh re mi fa
  # G G G G|
  # w:
  # F E F C|
  # w: fa mi re doh
  # If there are more syllables than available notes, any excess syllables will be ignored.
  # Recommendation for developers: If a w: line does not contain the correct number of syllables for the corresponding notes, the program should warn the user. However, having insufficient syllables is legitimate usage (as above) and so the program may allow these warnings to be switched off.
  # Note that syllables are not aligned on grace notes, rests or spacers and that tied, slurred or beamed notes are treated as separate notes in this context.
  # The lyrics lines are treated as text strings. Within the lyrics, the words should be separated by one or more spaces and to correctly align them the following symbols may be used:
  # Symbol	Meaning
  # -	 (hyphen) break between syllables within a word
  # _	 (underscore) previous syllable is to be held for an extra note
  # *	 one note is skipped (i.e. * is equivalent to a blank syllable)
  # ~	 appears as a space; aligns multiple words under one note
  # \-	 appears as hyphen; aligns multiple syllables under one note
  # |	 advances to the next bar
  # Note that if - is preceded by a space or another hyphen, the - is regarded as a separate syllable.
  # When an underscore is used next to a hyphen, the hyphen must always come first.
  # If there are not as many syllables as notes in a measure, typing a | automatically advances to the next bar; if there are enough syllables the | is just ignored.
  # Examples:
  # w: syll-a-ble    is aligned with three notes
  # w: syll-a--ble   is aligned with four notes
  # w: syll-a -ble   (equivalent to the previous line)
  # w: time__        is aligned with three notes
  # w: of~the~day    is treated as one syllable (i.e. aligned with one note)
  #                  but appears as three separate words
  #  gf|e2dc B2A2|B2G2 E2D2|.G2.G2 GABc|d4 B2
  # w: Sa-ys my au-l' wan to your aul' wan,
  # +: Will~ye come to the Wa-x-ies dar-gle?
  # See field continuation for the meaning of the +: field continuation.

  

end

