$LOAD_PATH << './'
require 'polyglot'
require 'treetop'
require 'lib/abc/abc-2.0-draft4.treetop'
require 'lib/abc/syntax-nodes.rb'
require 'lib/abc/parser.rb'
require 'lib/abc/voice.rb'
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
      p.transcriber.should == "me"
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
      p.transcriber.should == "me"
    end
    it "can start with comment lines" do
      p = parse "%comment\n%comment\nC:Madonna\nZ:me\n\nX:1\nT:Like a Prayer\nK:Dm"
      p.composer.should == "Madonna"
      p.transcriber.should == "me"
    end
    it "can end with comment lines" do
      p = parse "C:Madonna\nZ:me\n%comment\n%comment\n\nX:1\nT:Like a Prayer\nK:Dm"
      p.composer.should == "Madonna"
      p.transcriber.should == "me"
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

end

