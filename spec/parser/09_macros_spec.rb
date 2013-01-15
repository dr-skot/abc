# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('.')
require 'spec/parser/spec_helper'


# 9. Macros
# This standard defines an optional system of macros which is principally used to define the way in which ornament symbols such as the tilde ~ are played (although it could be used for many other purposes).
# Software implementing these macros, should first expand the macros defined in this section, and only afterwards apply any relevant U: replacement (see Redefinable symbols).
# When these macros are stored in an abc header file (see include field), they may form a powerful library.
# There are two kinds of macro, called Static and Transposing.

describe "m: (macro) field" do
  it "can appear in the tune header" do
    p = parse_value_fragment "m:~a3=a{d}a{e}a"
    p.macros['~a3'] = 'a{d}a{e}a'
  end
  it "can appear in the file header" do
    p = parse_value "m:~a3=a{d}a{e}a\n\nX:1\nT:\nK:C"
    p.macros['~a3'] = 'a{d}a{e}a'
  end
  it "can't appear in the tune body" do
    p = parse_fragment "abc\nm:~a3=a{d}a{e}a\ndef"
    p.errors[0].message.should == t('abc.errors.field_not_allowed')
  end
  it "can't appear as an inline field" do
    fail_to_parse_fragment "abc[m:~a3=a{d}a{e}a]def"
  end
end


  # 9.1 Static macros
  # You define a static macro by writing into the tune header something like this:
  #  m: ~G3 = G{A}G{F}G
  # When you play the tune, the program searches the tune header for macro definitions, then does a search and replace on its internal copy of the text before passing that to the parser which plays the tune. Every occurence of ~G3 in the tune is replaced by G{A}G{F}G, and that is what gets played. Only ~G3 notes are affected, ~G2, ~g3, ~F3 etc. are ignored.
  # You can put in as many macros as you want, and indeed, if you only use static macros you will need to write a separate macro for each combination of pitch and note-length. Here is an example:
  # X:50
  # T:Apples in Winter
  # S:Trad, arr. Paddy O'Brien
  # R:jig
  # m: ~g2 = {a}g{f}g
  # m: ~D2 = {E}D{C}D
  # M:6/8
  # K:D
  # G/2A/2|BEE dEE|BAG FGE|~D2D FDF|ABc ded|
  # BEE BAB|def ~g2 e|fdB AGF|GEE E2:|
  # d|efe edB|ege fdB|dec dAF|DFA def|
  # [1efe edB|def ~g2a|bgb afa|gee e2:|
  # [2edB def|gba ~g2e|fdB AGF|GEE E2||
  # Here I have put in two static macros, since there are two different notes in the tune marked with a tilde.
  # A static macro definition consists of four parts:
  # the field identifier m:
  # the target string - e.g ~G3
  # the equals sign
  # the replacement string - e.g. G{A}G{F}G
  # The target string can consist of any string up to 31 characters in length, except that it may not include the letter 'n', for reasons which will become obvious later. You don't have to use the tilde, but of course if you don't use a legal combination of abc, other programs will not be able to play your tune.
  # The replacement string consists of any legal abc text up to 200 characters in length. It's up to you to ensure that the target and replacement strings occupy the same time interval (the program does not check this). Both the target and replacement strings may include spaces if necessary, but leading and trailing spaces are stripped off so
  # m:~g2={a}g{f}g
  # is perfectly OK, although less readable.

  describe "a static macro" do
    it "can replace a target string with a replacement string in a file" do
      p = parse_value "X:1\nT:T\nm:~g2={a}g{f}g\nK:C\n~g2"
      p.tunes[0].notes.count.should == 2
      p.tunes[0].notes[0].grace_notes.notes[0].pitch.note.should == "A"
      p.tunes[0].notes[1].grace_notes.notes[0].pitch.note.should == "F"
    end
    it "can replace a target string with a replacement string in a fragment" do
      p = parse_value_fragment "m:~g2={a}g{f}g\nK:C\n~g2"
      p.notes.count.should == 2
      p.notes[0].grace_notes.notes[0].pitch.note.should == "A"
      p.notes[1].grace_notes.notes[0].pitch.note.should == "F"
    end
    it "can be one of many" do
      p = parse_value_fragment "m:~g2={a}g{f}g\nm:~D2={E}D{C}D\n~g2~D2"
      p.notes.count.should == 4
      p.notes[0].grace_notes.notes[0].pitch.note.should == "A"
      p.notes[1].grace_notes.notes[0].pitch.note.should == "F"
      p.notes[2].grace_notes.notes[0].pitch.note.should == "E"
      p.notes[3].grace_notes.notes[0].pitch.note.should == "C"
    end
    it "overwrites any prior macros having the same target" do
      p = parse_value_fragment "m:~g2={a}g{f}g\nm:~g2={f}g{a}g\n~g2"
      p.notes.count.should == 2
      p.notes[0].grace_notes.notes[0].pitch.note.should == "F"
      p.notes[1].grace_notes.notes[0].pitch.note.should == "A"
    end
    # TODO limit target to 31 chars
    # TODO limit replacement string to 200 characters
    it "strips off leading and trailing spaces on the target" do
      p = parse_value_fragment "m:    ~g2   ={a}g{f}g\nK:C\n~g2"
      p.notes.count.should == 2
    end
    it "strips off leading and trailing spaces on the replacement string" do
      p = parse_value_fragment "m:~g2=   {a}g{f}g  \nK:C\na~g2b"
      p.notes.count.should == 4
      p.notes[0].beam.should == :start
      p.notes[3].beam.should == :end
    end
    it "can replace a target string with a replacement string in a fragment" do
      p = parse_value_fragment "m:~g2={a}g{f}g\nK:C\n~g2"
      p.notes.count.should == 2
      p.notes[0].grace_notes.notes[0].pitch.note.should == "A"
      p.notes[1].grace_notes.notes[0].pitch.note.should == "F"
    end
    it "is applied to all tunes if it appears in the file header" do
      p = parse_value "m:~g2={a}g{f}g\n\nX:1\nT:T\nK:C\n~g2\n\nX:2\nT:T2\nK:D\n~g2"
      p.tunes[0].notes.count.should == 2
      p.tunes[1].notes.count.should == 2
    end
  end

  # TODO static macros are supposedly allowed in the file header and the tune body


  # 9.2 Transposing macros
  # If your tune has ornaments on lots of different notes, and you want them to all play with the same ornament pattern, you can use transposing macros to achieve this. Transposing macros are written in exactly the same way as static macros, except that the note symbol in the target string is represented by 'n' (meaning any note) and the note symbols in the replacement string by other letters (h to z) which are interpreted according to their position in the alphabet relative to n.
  # So, for example I could re-write the static macro m: ~G3 = G{A}G{F}G as a transposing macro m: ~n3 = n{o}n{m}n. When the transposing macro is expanded, any note of the form ~n3 will be replaced by the appropriate pattern of notes. Notes of the form ~n2 (or other lengths) will be ignored, so you will have to write separate transposing macros for each note length.
  # Here's an example:
  # X:35
  # T:Down the Broom
  # S:Trad, arr. Paddy O'Brien
  # R:reel
  # M:C|
  # m: ~n2 = (3o/n/m/ n                % One macro does for all four rolls
  # K:ADor
  # EAAG~A2 Bd|eg~g2 egdc|BGGF GAGE|~D2B,D GABG|
  # EAAG ~A2 Bd|eg~g2 egdg|eg~g2 dgba|gedB BAA2:|
  # ~a2ea agea|agbg agef|~g2dg Bgdg|gfga gede|
  # ~a2 ea agea|agbg ageg|dg~g2 dgba|gedB BA A2:|
  # A transposing macro definition consists of four parts:
  # the field identifier m:
  # the target string - e.g ~n3
  # the equals sign
  # the replacement string - e.g. n{o}n{m}n
  # The target string can consist of any string up to 31 characters in length, except that it must conclude with the letter 'n', followed by a number which specifies the note length.
  # The replacement string consists of any legal abc text up to 200 characters in length, where note pitches are defined by the letters h - z, the pitches being interpreted relative to that of the letter n. Once again you should ensure that the time intervals match. You should not use accidentals in transposing macros
  # Comment: It is almost impossible to think of a way to transpose ~=a3 or ~^G2 which will work correctly under all circumstances, so a static macro should be used for cases like these.

  # NOTE: there is no way under the current spec to write a transposing macro for ~=a3

  describe "a transposing macro" do
    it "can replace a target string with a replacement string in a file" do
      p = parse_value "X:1\nT:T\nm:~n3=n{o}n{m}n\nK:C\n~g3"
      p.tunes[0].notes.count.should == 3
      p.tunes[0].notes[0].grace_notes.should == nil
      p.tunes[0].notes[1].grace_notes.notes[0].pitch.note.should == "A"
      p.tunes[0].notes[2].grace_notes.notes[0].pitch.note.should == "F"
    end
    it "can replace a target string with a replacement string in a fragment" do
      p = parse_value_fragment "m:~n3=n{o}n{m}n\n~g3"
      p.notes.count.should == 3
      p.notes[0].grace_notes.should == nil
      p.notes[1].grace_notes.notes[0].pitch.note.should == "A"
      p.notes[2].grace_notes.notes[0].pitch.note.should == "F"
    end
    it "is applied to all tunes if it appears in the file header" do
      p = parse_value "m:~n2={o}n{m}n\n\nX:1\nT:T\nK:C\n~g2\n\nX:2\nT:T2\nK:D\n~a2"
      p.tunes[0].notes.count.should == 2
      p.tunes[1].notes.count.should == 2
    end
    it "transposes letters h-z" do
      p = parse_value_fragment "m:~n19=hijklmnopqrstuvwxyz\n~A19"
      p.notes.count.should == 19
      (0..18).each do |i|
        p.notes[i].pitch.note.should == 'BCDEFGA'[i % 7]
      end
      p.notes[0].pitch.octave.should == -1
      p.notes[18].pitch.octave.should == 2
    end
    it "doesn't transpose A-Z or a-g" do
      p = parse_value_fragment "m:~n19=HIJKLMNOPQRSTUVWabcdefgABCDEFGXZ\n~A19"
      p.notes.count.should == 16
      p.notes[0].embellishments.count.should == 16 # H-W parsed as embellisments on 1st note 'a'
      (0..13).each do |i|
        p.notes[i].pitch.note.should == 'ABCDEFGABCDEFG'[i]
        p.notes[i].pitch.octave.should == (i > 6 ? 0 : 1)
      end
      p.notes[14].is_a?(MeasureRest).should == true # X
      p.notes[15].is_a?(MeasureRest).should == true # Z
      fail_to_parse_fragment "m:~n2=YY\n~a2" # Y is illegal
    end
  end
