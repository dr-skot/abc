# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('.')
require 'spec/abc_standard/spec_helper'


  # 6. Typesetting and playback
  # 6.1 Typesetting
  # 6.1.1 Typesetting line-breaks
  # Terminology: Line-breaks in a document (also known in computing as new lines, line-feeds, carriage-returns, end-of-lines, etc.) determine how the document is set out on the page. Throughout this section, and elsewhere in the standard, a distinction should be noted between
  # a code line-break, meaning a line-break in the abc tune body, and, in particular, at the end of a line of music code;
  # a score line-break, meaning a line-break in the printed score.
  # The fundamental mechanism for typesetting score line-breaks is by using code line-breaks - one line of music code in the tune body normally corresponds to one line of printed music.
  # Of course the printed representation of a line of music code may be too long for the staff, so if necessary, typesetting programs should introduce additional score line-breaks. As a consequence, if you would prefer score line-breaks to be handled completely automatically (as is common in non-abc scoring software), then just type the tune body on a single line of music code.
  # Even though most abc GUI software should wrap over-long lines, typing the tune body on a single line may not always be convenient, particularly for users who wish to include code line-breaks to aid readability or if the abc code is to be emailed (see continuation of input lines).
  # Furthermore, in the past some typesetting programs used ! characters in the abc code to force score line-breaks.
  # As a result, abc 2.1 introduces a new line-breaking instruction.
  # I:linebreak
  # To allow for all line-breaking preferences, the I:linebreak instruction may be used, together with four possible values, to control score line-breaking.
  # "I:linebreak $" indicates that the $ symbol is used in the tune body to typeset a score line-break. Any code line-breaks are ignored for typesetting purposes.
  # Example: The following abc code should be typeset on two lines.

  # I:linebreak $
  # K:G
  # |:abc def|$fed cba:|

  # "I:linebreak !" indicates that the ! symbol is used to typeset a score line-break. Any code line-breaks are ignored for typesetting purposes.
  # Comment: The "I:linebreak !" instruction works in the same way as I:linebreak $ and is primarily provided for backwards compatibility - see line-breaking dialects, so that "I:linebreak $" is the preferred usage. "I:linebreak !" also automatically invokes the "I:decoration +" instruction - see decoration dialects. Finally, "I:linebreak !" is equivalent to the deprecated directive %%continueall true - see outdated directives.
  # "I:linebreak <EOL>" indicates that the End Of Line character (CR, LF or CRLF) is used to typeset a score line-break. In other words, code line-breaks are used for typesetting score line-breaks.
  # "I:linebreak <none>" indicates that all line-breaking is to be carried out automatically and any code line-breaks are ignored for typesetting purposes.
  # The values <EOL>, $ and ! may also be combined so that more that one symbol can indicate a score line-break.
  # The default line-break setting is:
  # I:linebreak <EOL> $
  # meaning that both code line-breaks, and $ symbols, generate a score line-break.
  # Comment: Although "I:linebreak $ !" is legal it is not recommended as it uses two different symbols to mean the same thing.
  # An I:linebreak instruction can be used either in the file header (in which case it is applied to every tune in the abc file), or in a tune header (in which case it is applied to that tune only and overrides a line-breaking instruction in the file header). Similarly, if two I:linebreak instructions appear in a file header or a tune header, the second cancels the first.
  # Comment: It can be sometimes be useful to include two instructions together - for example, "I:linebreak <EOL> $" and "I:linebreak <none>" can be used to toggle between default and automatic line-breaking simply by swapping the position of the two lines.
  # I:linebreak instructions are not allowed in the tune body (principally because it conflicts with the human readability of the music code).

  # Suppressing score line-breaks
  # When the <EOL> character is being used in the tune body to indicate score line-breaks, it sometimes useful to be able to tell typesetting software to ignore a particular code line-breaks. This is achieved using a backslash (\) at the end of a line of music code. The backslash may be followed by trailing whitespace and/or comments, since they are removed before the line is processed.
  # Example: The following two excerpts are considered equivalent and should be typeset as a single staff in the printed score.

  # abc cba|\ % end of line comment
  # abc cba|

  # abc cba|abc cba|

  # The backslash effectively joins two lines together for processing so if space is required between the two half lines (for example, to prevent the notes from being beamed together), it can be placed before the backslash, or at the beginning of the next half line.
  # Example: The following three excerpts are considered equivalent.

  # abc \
  # cba|

  # abc\
  #  cba|

  # abc cba|  

  # There is no limit to the number of lines that may be joined together in this way. However, a backslash must not be used before an empty line.
  # Example: The following is legal.

  # cdef|\
  # \
  # cedf:|
  # Example: The following is not legal.

  # cdef|\
  #
  # cdef:|

  # In the examples above, where a line of music code follows immediately after a line ending in backslash, the backslash acts as a continuation for two lines of music code and can therefore be used to split up long music code lines.
  # More importantly, however, any information fields and stylesheet directives are processed (and comments are removed) at the point where the physical line-break occurs. Hence the backslash is commonly used to include meter or key changes halfway through a line of music.
  # Example: The following should be typeset as a single staff in the printed score.

  # abc cab|\
  # %%setbarnb 10
  # M:9/8
  # %comment
  # abc cba abc|

  # Alternative usage example: The above could also be achieved using inline fields, the I:<directive> form instead of %%<directive> and a r:remark in place of the comment, i.e.

  # abc cab|[I:setbarnb 10][M:9/8][r:comment]abc cba abc|

  # Finally, note that if the the <EOL> character is not being used to indicate score line-breaks, then the backslash is effectively redundant.
  # Recommendation to users: If you find that you are using backslash symbols on most lines of music code, then consider instead using "I:linebreak <none>" or "I:linebreak $" which will mean that all the code line-breaks will be ignored for the purposes of generating score line-breaks (and, in the latter case, you can encode a score line-breaks with the $ character).

  describe "a linebreak" do
    it "is caused by a linebreak in the music code" do
      p = parse_value_fragment "abc\ndef\ngab"
      p.lines.count.should == 3
    end
    it "can be explicitly indicated with $" do
      p = parse_value_fragment "abc$def$g$ab"
      p.lines.count.should == 4
    end
    it "cannot by default be indicated with !" do
      p = parse_value_fragment "abc!def!gab"
      p.lines.count.should == 1
      p.notes[3].decorations[0].symbol.should == "def"
    end
  end

  describe "the I:linebreak instruction" do
    it "can set the linebreak character to ! only" do
      p = parse_value_fragment "I:linebreak !\nabc!def!gab"
      p.lines.count.should == 3
      fail_to_parse_fragment "I:linebreak !\nabc$def$gab"
      p = parse_value_fragment "I:linebreak !\nabc\ndef\ngab"
      p.lines.count.should == 1
    end
    it "can set the linebreak character to $ only" do
      p = parse_value_fragment "I:linebreak $\nabc$def$gab"
      p.lines.count.should == 3
      p = parse_value_fragment "I:linebreak $\nabc!def!gab"
      p.lines.count.should == 1
      p = parse_value_fragment "I:linebreak $\nabc\ndef\ngab"
      p.lines.count.should == 1
    end
    it "can set the linebreak character to <EOL> only" do
      p = parse_value_fragment "I:linebreak <EOL>\nabc\ndef\ngab"
      p.lines.count.should == 3
      fail_to_parse_fragment "I:linebreak <EOL>\nabc$def$gab"
      p = parse_value_fragment "I:linebreak <EOL>\nabc!def!gab"
      p.lines.count.should == 1
    end
    it "can set the linebreak characters to $ <EOL>" do
      p = parse_value_fragment "I:linebreak $ <EOL>\nabc\ndef\ngab"
      p.lines.count.should == 3
      p = parse_value_fragment "I:linebreak $ <EOL>\nabc$def$gab"
      p.lines.count.should == 3
      p = parse_value_fragment "I:linebreak $ <EOL>\nabc!def!gab"
      p.lines.count.should == 1
    end
    it "can set the linebreak characters to ! <EOL>" do
      p = parse_value_fragment "I:linebreak ! <EOL>\nabc\ndef\ngab"
      p.lines.count.should == 3
      fail_to_parse_fragment "I:linebreak ! <EOL>\nabc$def$gab"
      p = parse_value_fragment "I:linebreak ! <EOL>\nabc!def!gab"
      p.lines.count.should == 3
    end
    it "can set the linebreak characters to $ !" do
      p = parse_value_fragment "I:linebreak $ ! \nabc\ndef\ngab"
      p.lines.count.should == 1
      p = parse_value_fragment "I:linebreak $ ! \nabc$def$gab"
      p.lines.count.should == 3
      p = parse_value_fragment "I:linebreak $ ! \nabc!def!gab"
      p.lines.count.should == 3
    end
    it "can set the linebreak character to <none>" do
      p = parse_value_fragment "I:linebreak <none>\nabc\ndef\ngab"
      p.lines.count.should == 1
      fail_to_parse_fragment "I:linebreak <none>\nabc$def$gab"
      p = parse_value_fragment "I:linebreak <none>\nabc!def!gab"
      p.lines.count.should == 1
    end
    it "sets the decoration delimiter to + if any linebreak character is !" do
      p = parse_value_fragment "I:linebreak !\n+trill+abc"
      p.notes[0].decorations[0].symbol.should == 'trill'
      p = parse_value_fragment "I:linebreak ! <EOL>\n+trill+abc"
      p.notes[0].decorations[0].symbol.should == 'trill'
      p = parse_value_fragment "I:linebreak $ !\n+trill+abc"
      p.notes[0].decorations[0].symbol.should == 'trill'
    end
    it "should reset for each tune" do
      p = parse_value "X:1\nT:T\nI:linebreak !\nK:C\nabc!def!g\n\nX:2\nT:T2\nK:D\nabc!d!ef\ng"
      p.tunes[0].lines.count.should == 3
      p.tunes[1].lines.count.should == 2
    end
    it "can appear in the file header" do
      p = parse_value "I:linebreak !\n\nX:1\nT:T\nK:C\nabc!def!g\n\nX:2\nT:T2\nK:D\nabc!d!ef\ng"
      p.tunes[0].lines.count.should == 3
      p.tunes[1].lines.count.should == 3
    end
    it "cannot appear in the tune body" do
      p = fail_to_parse_fragment "K:C\nI:linebreak !\nabc!def"
    end
    it "can override values in the file header" do
      p = parse_value ["I:linebreak $",
                 "X:1\nT:T1\nI:linebreak $ <EOL>\nK:D\nabc\nef$g",
                 "X:2\nT:T2\nK:C\nabc\ndef$g"].join("\n\n")
      p.tunes[0].lines.count.should == 3
      p.tunes[1].lines.count.should == 2
    end
    it "overrides previous values in the same header" do
      p = parse_value_fragment "I:linebreak <EOL>\nI:linebreak !\nabc\ndef\nabc!def"
      p.instructions['linebreak'].should == '!'
      p.lines.count.should == 2
    end
    it "has the I:decoration + side effect for only 1 tune if it appears in the tune header" do
      p = parse_value ["X:1\nT:T1\nI:linebreak !\nK:D\nabc!+p+def!g",
                 "X:2\nT:T2\nK:C\nabc!p!def$g"].join("\n\n")
      p.tunes[0].lines.count.should == 3
      p.tunes[0].notes[3].decorations[0].symbol.should == 'p'
      p.tunes[1].lines.count.should == 2
      p.tunes[1].notes[3].decorations[0].symbol.should == 'p'
    end
  end

  describe "a backslash" do
    it "does not break beaming" do
      p = parse_value_fragment "a\\\nb"
      p.notes[0].beam.should == :start
    end
    it "cannot be followed by a blank line" do
      p = fail_to_parse_fragment "a\\\n   \nb"
    end
  end


  # 6.1.2 Typesetting extra space
  # y can be used to add extra space between the surrounding notes; moreover, chord symbols and decorations can be attached to it, to separate them from notes.
  # Example:
  # "Am" !pp! y
  # Note that the y symbol does not create rests in the music.

  describe "a spacer" do
    it "can be inserted between notes" do
      p = parse_value_fragment "ayb"
      p.items[1].type.should == :spacer
    end
    it "can have decorations attached to it" do
      p = parse_value_fragment 'a "Am" !pp! y b'
      p.items[1].chord_symbol.text.should == "Am"
      p.items[1].decorations[0].symbol.should == "pp"
    end
    it "does not create rests in the music" do
      p = parse_value_fragment "ayb"
      p.items[1].is_a?(MusicUnit).should == false
      p.items[1].respond_to?(:length).should == false
    end
  end
