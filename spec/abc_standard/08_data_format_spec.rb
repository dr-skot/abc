# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('.')
require 'spec/abc_standard/spec_helper'

  # 8. Abc data format
  # Each line in the file may end with white-space which will be ignored. For the purpose of this standard, ASCII tab and space characters are equivalent and are both included in the term 'white-space'. Applications must be able to interpret end-of-line markers in Unix (<LF>), Windows/DOS (<CR><LF>), and Macintosh style (<CR>) correctly.

  describe "whitespace" do
    it "is ignored at the end of a header line" do
      p = parse_value_fragment "T:Adeste Fideles     "
      p.title.should == "Adeste Fideles"
    end
    it "is ignored at the end of a music line" do
      p = parse_value_fragment "abc\\     \nd"
      p.notes[2].beam.should == :middle
    end
    it "can be spaces or tabs" do
      p = parse_value_fragment "T:Adeste Fideles\t\t\t"
      p.title.should == "Adeste Fideles"
    end
  end

  describe "a line ending" do
    it "can be unix-style (<LF>)" do
      p = parse_value_fragment "T:Respect\nC:Otis Redding"
      p.title.should == "Respect"
      p.composer.should == "Otis Redding"
    end
    it "can be windows-style (<CR><LF>)" do
      p = parse_value_fragment "T:Respect\r\nC:Otis Redding"
      p.title.should == "Respect"
      p.composer.should == "Otis Redding"
    end
    it "can be mac-style (<CR>)" do
      p = parse_value_fragment "T:Respect\rC:Otis Redding"
      p.title.should == "Respect"
      p.composer.should == "Otis Redding"
    end
  end


  # 8.1 Tune body
  # Within the tune body, all the printable ASCII characters may be used for the music code. These are:
  #  !"#$%&'()*+,-./0123456789:;<=>?@
  # ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`
  # abcdefghijklmnopqrstuvwxyz{|}~
  # Of these, the following characters are currently reserved:
  # # * ; ? @
  # In future standards they may be used to extend the abc syntax.
  # To ensure forward compatibility, current software should ignore these characters when they appear inside or between note groups, possibly giving a warning. However, these characters may not be ignored when they appear inside text strings or information fields.
  # Example:
  # @a !pp! #bc2/3* [K:C#] de?f "@this $2was difficult to parse?" y |**
  # should be treated as:
  # a !pp! bc2/3 [K:C#] def "@this $2was difficult to parse?" y |

  describe "a reserved character (# * ; ? @)" do
    it "is ignored as a note embellishment" do
      '#*;?@'.each_char do |char|
        p = parse_value_fragment "#{char}a"
        p.elements.count.should == 2
        p.elements[0].is_a?(Note).should == true
        p.elements[0].pitch.note.should == "A"
        p.elements[0].pitch.accidental.should == nil
        p.elements[0].embellishments.should == []
        p.elements[0].chord_symbol.should == nil
        p.elements[0].grace_notes.should == nil
        p.elements[1].type.should == :code_linebreak
      end
    end
    it "is ignored between note groups" do
      '#*;?@'.each_char do |char|
        p = parse_value_fragment "a#{char}[ceg]"
        p.elements.count.should == 3
        p.elements[0].is_a?(Note).should == true
        p.elements[1].is_a?(Chord).should == true
        p.elements[2].type.should == :code_linebreak
      end
    end
    it "is ignored between note embellishments" do
      '#*;?@'.each_char do |char|
        p = parse_value_fragment('A {gege}#<#"Gm"#!p!#!trill!#u#"^annoted"#B'.gsub('#', char))
        p.elements.count.should == 4
        (a = p.elements[0]).is_a?(Note).should == true
        p.elements[1].type.should == :beam_break
        (b = p.elements[2]).is_a?(Note).should == true
        p.elements[3].type.should == :code_linebreak
        b.grace_notes.notes.count.should == 4
        b.embellishments.count.should == 5
        b.embellishments[0].text.should == "Gm"
        b.embellishments[1].symbol.should == "p"
        b.embellishments[2].symbol.should == "trill"
        b.embellishments[3].symbol.should == "upbow"
        b.embellishments[4].text.should == "annoted"
        b.pitch.note.should == "B"
      end
    end
  end


  # 8.2 Text strings
  # Text written within an abc file, either as part of an information field, an annotation or as free text / typeset text, is known as a text string, or more fully, an abc text string. (Note that the abc standard version 2.0 referred to a text string as an abc string.)
  # Typically when there are several lines of text, each line forms a separate text string, although the distinction is not essential.
  # The contents of a text string may be written using any legal character set. The default character set is utf-8, giving access to every Unicode character.
  # However, not all text editors support utf-8 and so to avoid portability problems when writing accented characters in text strings, it also possible to use three other encoding options:
  # mnemonics - for example, é can be represented by \'e. These mnemonics are are based on TeX encodings and are always in the format backslash-mnemonic-letter. They have been available since the earliest days of abc and are widely used in legacy abc files. They are generally easy to remember and easy to read, but are not comprehensive in terms of the possible accents they can represent.
  # named html entities - for example, é can be represented by &eacute;. These encodings are not common in legacy abc files but are convenient for websites which use abc and generally easy to remember. However they are not particularly easy to read and are not fully comprehensive in terms of the possible accents they can represent.
  # fixed width unicode - for example, é can be represented by \u00e9 using the 16-bit unicode representation 00e9 (or \U000000e9 using 32-bit). These encodings are not common in legacy abc files and are not easy to read but give comprehensive access to all unicode characters.
  # All conforming abc typesetting software should support (understand and be able to convert) the subset of accents and ligatures given in the appendix, supported accents & ligatures, together with the special characters and symbols listed below.
  # A summary, with examples, is as follows:

  # Accent	 Examples	 Encodings
  # grave	À à è ò	\`A \`a \`e \`o
  # acute	Á á é ó	\'A \'a \'e \'o
  # circumflex	Â â ê ô	\^A \^a \^e \^o
  # tilde	Ã ã ñ õ	\~A \~a \~n \~o
  # umlaut	Ä ä ë ö	\"A \"a \"e \"o
  # cedilla	Ç ç	\cC \cc
  # ring	Å å	\AA \aa
  # slash	Ø ø	\/O \/o
  # breve	Ă ă Ĕ ĕ	\uA \ua \uE \ue
  # caron	Š š Ž ž	\vS \vs \vZ \vz
  # double acute	Ő ő Ű ű	\HO \Ho \HU \Hu
  # ligatures	ß Æ æ œ	\ss \AE \ae \oe

  # Programs that have difficulty typesetting accented letters may reduce them to the base letter or, in the case of ligatures, the two base letters ignoring the backslash.
  # Examples: When reduced to the base letter, \oA becomes A, \"o becomes o, \ss becomes ss, \AE becomes AE, etc.
  # For fixed width unicode, \u or \U must be followed by 4 or 8 hexadecimal characters respectively. Thus if any of the 4 characters after \u is not hexadecimal, then it is interpreted as a breve.
  # Special characters
  # Characters that are meaningful in the context of a text string can be escaped using a backslash as follows:
  # type \\ to get a backslash;
  # type \% to get a percent symbol that is not interpreted as the start of a comment;
  # type \& to get an ampersand that is not interpreted as the start of a named html entity (although an ampersand followed by white-space is interpreted as is - for example, gin & tonic is OK, but G\&T requires the backslash);
  # type &quot; or \u0022 to get double quote marks in an annotation
  # Special symbols
  # The following symbols are also useful:
  # type &copy; or \u00a9 for the copyright symbol ©
  # type \u266d for a flat symbol ♭
  # type \u266e for a natural symbol ♮
  # type \u266f for a sharp symbol ♯
  # VOLATILE: Finally note that currently the specifiers $1, $2, $3 and $4 can be used to change the font within a text string. However, this feature is likely to change in future versions of the standard - see font directives for more details.

  describe "a text string" do
    it "is what the value of a string field is" do
      p = parse_value_fragment "T:Title"
      p.title.is_a?(ABC::TextString).should == true
    end
    it "is what the value of an inline string field is" do
      p = parse_value_fragment "[N:notation]abc"
      p.items[0].value.is_a?(ABC::TextString).should == true
    end
    it "is what an annotation is" do
      p = parse_value_fragment '"^an annotation"C'
      p.notes[0].annotations[0].text.is_a?(ABC::TextString).should == true
    end
    it "is what free text is" do
      p = parse_value "free text\n\nX:1\nT:T\nK:C"
      p.sections[0].text.is_a?(ABC::TextString).should == true
    end
    # TODO uh oh typeset text isn't working
    # it "is what typeset text is" do
    #   p = parse_value '%%text typeset text\n\nX:1\nT:T\nK:C'
    #   p.sections[0].text.is_a?(ABC::TextString).should == true
    # end
    it "interprets mnemonics" do
      TextString.new("\\`e").should == "è"
    end
    it "interprets named html entities" do
      TextString.new("&egrave;").should == "è"
    end
    it "interprets 16-bit fixed width unicode codes" do
      TextString.new("\\u00e8").should == "è"
      TextString.new("\\u266d").should == "♭"
    end
    it "interprets 32-bit fixed width unicode codes" do
      TextString.new("\\U000000e8").should == "è"
      TextString.new("\\U0000266d").should == "♭"
    end
    it "escapes backslash with backslash" do
      TextString.new("\\\\`e").should == "\\`e"
      TextString.new("\\\\u00e8").should == "\\u00e8"
    end
    it "escapes ampersand with backslash" do
      TextString.new("\\&egrave;").should == "&egrave;"
    end
  end

