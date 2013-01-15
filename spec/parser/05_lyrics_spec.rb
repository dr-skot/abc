# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('.')
require 'spec/parser/spec_helper'


# 5. Lyrics
# The W: information field (uppercase W) can be used for lyrics to be printed separately below the tune.
# The w: information field (lowercase w) in the tune body, supplies lyrics to be aligned syllable by syllable with previous notes of the current voice.

describe "W: (words, unaligned) field" do
  it "can appear in the tune header" do
    p = parse_value_fragment "W: Da doo run run run"
    p.unaligned_lyrics.should == "Da doo run run run"
    p.words.should == "Da doo run run run"
  end
  it "can't appear in the file header" do
    p = parse "W:doo wop she bop\n\nX:1\nT:\nK:C"
    p.errors[0].message.should == "invalid file header"
  end
  it "can appear in the tune body" do
    p = parse_value_fragment "abc\nW:doo wop she bop\ndef"
    p.items[3].value.should == "doo wop she bop"
  end
  it "can't appear as an inline field" do
    p = parse_fragment "abc[W:doo wop she bop]def"
    p.errors[0].message.should == t('abc.errors.field_not_allowed')
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
  
  describe "lyric alignment" do

    it "matches syllables to notes" do
      p = parse_value_fragment "GCEA\nw:My dog has fleas"
      p.notes[0].lyric.text.should == "My"
      p.notes[1].lyric.text.should == "dog"
      p.notes[2].lyric.text.should == "has"
      p.notes[3].lyric.text.should == "fleas"
    end

    it "starts at the first note of the voice if there is no previous w: field" do
      p = parse_value_fragment "[V:1]G,G,G,A,[V:2]GCEA\nw:My dog has fleas"
      p.notes[0].lyric.should == nil
      p.notes[1].lyric.should == nil
      p.notes[2].lyric.should == nil
      p.notes[3].lyric.should == nil
      p.all_notes[4].lyric.text.should == "My"
      p.all_notes[5].lyric.text.should == "dog"
      p.all_notes[6].lyric.text.should == "has"
      p.all_notes[7].lyric.text.should == "fleas"
    end

    it "starts at the first note after the notes aligned to the previous w: field" do
      p = parse_value_fragment "G \nw:My dog has \nA\nw: fleas"
      p.notes[1].lyric.text.should == "fleas"
    end

    it "reaches back across linebreaks" do
      p = parse_value_fragment "C D E F|\nG A B c|\nw: doh re mi fa sol la ti doh"
      p.notes[0].lyric.text.should == "doh"
      p.notes[6].lyric.text.should == "ti"
      p.notes[7].lyric.text.should == "doh"
    end

    it "ignores excess syllables" do
      p = parse_value_fragment "GC\nw:My dog has fleas\nEA2"
      p.notes[0].lyric.text.should == "My"
      p.notes[1].lyric.text.should == "dog"
      p.notes[2].lyric.should == nil
      p.notes[3].lyric.should == nil
    end
    
    it "can explicitly blank lyrics from notes" do
      p = parse_value_fragment "C D E F|\nw: doh re mi fa\nG G G G|\nw:\nF E F C|\nw: fa mi re doh"
      p.notes[3].lyric.text.should == "fa"
      p.notes[4].lyric.should == nil
      p.notes[7].lyric.should == nil
      p.notes[8].lyric.text.should == "fa"
    end
    
    it "does not match syllables to grace notes" do
      p = parse_value_fragment "{gege}GCAE\nw:My dog has fleas"
      p.notes[0].grace_notes.notes[0].lyric.should == nil
      p.notes[0].lyric.text.should == "My"
    end

    it "does not match syllables to rests" do
      p = parse_value_fragment "GCEz4A4\nw:My dog has fleas"
      p.notes[3].lyric.should == nil
      p.notes[4].lyric.text.should == "fleas"
    end

    it "does not match syllables to spacers" do
      p = parse_value_fragment "GCEyA4\nw:My dog has fleas"
      p.items[3].respond_to?(:lyric).should be_false
      p.items[4].lyric.text.should == "fleas"
    end

    it "aligns syllables separately to tied notes" do
      p = parse_value_fragment "GCE-EA\nw:My dog has fleas"
      p.notes[3].tied_left.should == true
      p.notes[3].pitch.note.should == "E"
      p.notes[3].lyric.text.should == "fleas"
      p.notes[4].lyric.should == nil
    end

    it "aligns syllables separately to slurred notes" do
      p = parse_value_fragment "GC(EA)g\nw:My dog has fleas"
      p.notes[3].end_slur.should > 0
      p.notes[3].pitch.note.should == "A"
      p.notes[3].lyric.text.should == "fleas"
      p.notes[4].lyric.should == nil
    end
    it "can set one syllable to 2 notes" do
      p = parse_value_fragment "FDB\nw:O_ say can you see"
      p.notes[0].lyric.text.should == "O"
      p.notes[0].lyric.note_count.should == 2
      p.notes[1].lyric.should == nil
      p.notes[2].lyric.text.should == "say"
      p.notes[2].lyric.note_count.should == 1
    end

    it "can set one syllable to 3 notes" do
      p = parse_value_fragment "FDdB\nw:O__ say can you see"
      p.notes[0].lyric.text.should == "O"
      p.notes[0].lyric.note_count.should == 3
      p.notes[1].lyric.should == nil
      p.notes[2].lyric.should == nil
      p.notes[3].lyric.text.should == "say"
      p.notes[3].lyric.note_count.should == 1
    end

    it "splits syllables with a hyphen" do
      p = parse_value_fragment "ccGEB\nw:gal-lant-ly stream-ing"
      p.notes[0].lyric.text.should == "gal"
      p.notes[0].lyric.hyphen?.should == true
      p.notes[1].lyric.text.should == "lant"
      p.notes[1].lyric.hyphen?.should == true
      p.notes[2].lyric.text.should == "ly"
      p.notes[2].lyric.hyphen?.should == false
    end

    it "suppports hyphen and underscore together" do
      p = parse_value_fragment "d2fedcb4\nw:ban-_ner yet_ wave"
      p.notes[0].lyric.text.should == "ban"
      p.notes[0].lyric.hyphen?.should == true
      p.notes[0].lyric.note_count.should == 2
      p.notes[2].lyric.text.should == "ner"
      p.notes[2].lyric.hyphen?.should == false
    end

    it "stretches syllables with double hyphen" do
      p = parse_value_fragment "d2fedcb4\nw:ban--ner yet_ wave"
      p.notes[0].lyric.text.should == "ban"
      p.notes[0].lyric.hyphen?.should == true
      p.notes[0].lyric.note_count.should == 2
      p.notes[2].lyric.text.should == "ner"
      p.notes[2].lyric.hyphen?.should == false
    end

    it "stretches syllables with space+hyphen" do
      p = parse_value_fragment "d2fedcb4\nw:ban -ner yet_ wave"
      p.notes[0].lyric.text.should == "ban"
      p.notes[0].lyric.hyphen?.should == true
      p.notes[0].lyric.note_count.should == 2
      p.notes[2].lyric.text.should == "ner"
      p.notes[2].lyric.hyphen?.should == false
    end

    it "skips notes with *" do
      p = parse_value_fragment "acddc\nw:*see ** see"
      p.notes[0].lyric.should == nil
      p.notes[1].lyric.text.should == "see"
      p.notes[1].lyric.note_count.should == 1
      p.notes[2].lyric.should == nil
      p.notes[3].lyric.should == nil
      p.notes[4].lyric.text.should == "see"
      p.notes[4].lyric.note_count.should == 1
    end

    it "preserves spaces with ~" do
      p = parse_value_fragment "abc\nw:go~on get jiggy with it"
      p.notes[0].lyric.text.should == "go on"
      p.notes[1].lyric.text.should == "get"
    end

    it "escapes hyphens with backslash" do
      p = parse_value_fragment "abc\nw:x\\-ray"
      p.notes[0].lyric.text.should == "x-ray"
    end

    it "advances to the next bar with |" do
      p = parse_value_fragment "abc|def\nw:yeah|yeah"
      p.notes[0].lyric.text.should == "yeah"
      p.notes[0].lyric.note_count.should == 1
      p.notes[1].lyric.should == nil
      p.notes[2].lyric.should == nil
      p.notes[3].lyric.text.should == "yeah"
    end

    it "ignores dotted bar lines when skipping to next bar" do
      p = parse_value_fragment("abc.|de|f\nw:hey|jude")
      p.notes[0].lyric.text.should == "hey"
      p.notes[3].lyric.should == nil
      p.notes[5].lyric.text.should == "jude"
    end

  end


  # 5.2 Verses
  # It is possible for a music line to be followed by several adjacent w: fields, i.e. immediately after each other. This can be used, together with part notation, to represent different verses. The first w: field is used the first time that part is played, then the second and so on.
  # Examples: The following two examples are equivalent and contain two verses:
  # CDEF FEDC|
  # w: these are the lyr-ics for verse one
  # w: these are the lyr-ics for verse two
  # CDEF FEDC|
  # w: these are the lyr-ics
  # +:  for verse one
  # w: these are the lyr-ics
  # +:  for verse two  
  
  describe "lyric alignment" do

    it "sets different verses with consecutive w: lines" do
      p = parse_value_fragment "GCEA\nw:My dog\nw:has fleas"
      p.notes[0].lyric.text.should == "My"
      p.notes[1].lyric.text.should == "dog"
      p.notes[0].lyrics[1].text.should == "has"
      p.notes[1].lyrics[1].text.should == "fleas"
      p.notes[2].lyric.should == nil
      p.notes[3].lyric.should == nil
    end

    it "verses reset to just after last w: line" do
      p = parse_value_fragment "ABC\nw:A B C\nGCEA\nw:My dog\nw:has fleas"
      p.notes[0].lyric.text.should == "A"
      p.notes[0].lyrics.count.should == 1
      p.notes[3].lyric.text.should == "My"
      p.notes[3].lyrics[1].text.should == "has"
    end

    it "does not change verses when continuing the w: line with +:" do
      p = parse_value_fragment "GCEA\nw:My dog\n+:has fleas"
      p.notes[0].lyric.text.should == "My"
      p.notes[1].lyric.text.should == "dog"
      p.notes[2].lyric.text.should == "has"
      p.notes[3].lyric.text.should == "fleas"
    end

    # TODO provide Voice::lyrics and Tune::lyrics to recover all aligned lyrics
    # as an array of verses, where each verse is a string like "My dog ha-as fleas"

  end


  # 5.3 Numbering
  # VOLATILE: The following syntax may be extended to include non-numeric "numbering".
  # If the first word of a w: line starts with a digit, this is interpreted as numbering of a stanza. Typesetting programs should align the corresponding note with the first letter that occurs. This can be used in conjunction with the ~ symbol mentioned in the table above to create a space between the digit and the first letter.
  # Example: In the following, the 1.~Three is treated as a single word with a space created by the ~, but the fact that the w: line starts with a number means that the first note of the corresponding music line is aligned to Three.
  #    w: 1.~Three blind mice

  # ^^ TODO special handling of stanza numbers?

