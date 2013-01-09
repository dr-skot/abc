# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('.')
require 'spec/abc_standard/spec_helper'


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
      p = parse_value_fragment "CDEFGAB"
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
      p = parse_value_fragment "cdefgab"
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
      p = parse_value_fragment "C'c'''"
      p.notes[0].pitch.octave.should == 1
      p.notes[1].pitch.octave.should == 4
    end
    it "indicates lower octave down with commas" do
      p = parse_value_fragment "C,,,,c,,"
      p.notes[0].pitch.octave.should == -4
      p.notes[1].pitch.octave.should == -1
    end
    it "can use any combination of commas and apostrophes" do
      p = parse_value_fragment "C,',',,c,,'''',"
      p.notes[0].pitch.octave.should == -2
      p.notes[1].pitch.octave.should == 2
    end
    # TODO make this work when we get to clef
    it "can be octave-shifted by the K: field" do
       p = parse_value_fragment "[K:treble-8]C"
       p.notes[0].pitch.octave.should == -1
    end
    it "can be octave-shifted by the K: field in the header" do
       p = parse_value_fragment "K:treble-8\nC"
       p.notes[0].pitch.octave.should == -1
    end
    it "can be octave-shifted by the K: field inline" do
       p = parse_value_fragment "[K:treble-8]C"
       p.notes[0].pitch.octave.should == -1
    end
    it "can be octave-shifted by the V: field" do
       p = parse_value_fragment "V:1 treble+8\nK:C\n[V:1]C"
       p.voices['1'].notes[0].pitch.octave.should == 1
    end
    it "will not have its octave-shift canceled by a K: field with no clef" do
       p = parse_value_fragment "V:1 treble+8\nK:C\n[V:1][K:D]C"
       p.voices['1'].notes[0].pitch.clef.should == p.voices['1'].clef
       p.voices['1'].notes[0].pitch.octave.should == 1
    end
    it "will use the tune's clef if the voice doesn't specify one" do
       p = parse_value_fragment "K:treble+8\n[V:1]C"
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
      p = parse_value_fragment "^A^^a2_b/__C=DF"
      p.notes[0].pitch.accidental.should == 1
      p.notes[1].pitch.accidental.should == 2
      p.notes[2].pitch.accidental.should == -1
      p.notes[3].pitch.accidental.should == -2
      p.notes[4].pitch.accidental.should == 0
      p.notes[5].pitch.accidental.should == nil
    end
    it "changes the height of the corresponding note" do
      p = parse_value_fragment "^C^^C2_C/__C=CC"
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
      p = parse_value_fragment "L:1\na"
      p.notes[0].note_length.should == 1
    end
    it "can be an integer multiplier" do
      p = parse_value_fragment "L:1\na3"
      p.notes[0].note_length.should == 3
    end
    it "can be a simple fraction" do
      p = parse_value_fragment "L:1\na3/2"
      p.notes[0].note_length.should == Rational(3,2)
    end
    it "can be slashes" do
      p = parse_value_fragment "L:1\na///"
      p.notes[0].note_length.should == Rational(1, 8)
    end
    it "is relative to the default unit note length" do
      p = parse_value_fragment "ab2c3/2d3/e/" # default unit note length 1/8
      p.notes[0].note_length.should == Rational(1, 8)
      p.notes[1].note_length.should == Rational(1, 4)
      p.notes[2].note_length.should == Rational(3, 16)
      p.notes[3].note_length.should == Rational(3, 16)
      p.notes[4].note_length.should == Rational(1, 16)
    end
    it "is relative to an explicit unit note length" do
      p = parse_value_fragment "L:1/2\nab2c3/2d3/e/"
      tune = p
      tune.notes[0].note_length.should == Rational(1, 2)
      tune.notes[1].note_length.should == 1
      tune.notes[2].note_length.should == Rational(3, 4)
      tune.notes[3].note_length.should == Rational(3, 4)
      tune.notes[4].note_length.should == Rational(1, 4)
    end
     it "is relative to a new unit note length after an L: field in the tune body" do
      p = parse_value_fragment "L:1/2\na4\nL:1/4\na4"
      tune = p
      tune.notes[0].note_length.should == 2
      tune.notes[1].note_length.should == 1
    end
    it "is relative to a new unit note length after an inline L: field" do
      p = parse_value_fragment "L:1/2\na4[L:1/4]a4"
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
      p = parse_value_fragment "a>b"
      p.items[0].broken_rhythm_marker.should == nil
      p.items[1].broken_rhythm_marker.change('>').should == Rational(1, 2)
    end
    it "alters note lengths appropriately" do
      tune = parse_value_fragment "L:1\na>b c<d e<<f g>>>a"
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
      p = parse_value_fragment "a>b"
      p.items[0].note_length.should == Rational(3, 16)
      p.items[1].note_length.should == Rational(1, 16)
    end
    it "works with note length specifiers" do
      p = parse_value_fragment "a2>b2"
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
      p = parse_value_fragment "L:1\n z3/2 z//"
      p.items[0].length.should == Rational(3, 2)
      p.items[1].length.should == Rational(1, 4)
    end
    it "cannot have a bizarro length specifier" do
      fail_to_parse_fragment "z3//4"
    end
    it "knows it's visible" do
      p = parse_value_fragment "z"
      p.items[0].invisible?.should == false
    end
  end
  
  describe "an invisible rest (x)" do
    it "can appear with a length specifier" do
      p = parse_value_fragment "L:1\n x3/2 x//"
      p.items[0].length.should == Rational(3, 2)
      p.items[1].length.should == Rational(1, 4)
    end
    it "cannot have a bizarro length specifier" do
      fail_to_parse_fragment "x3//4"
    end
    it "knows it's invisible" do
      p = parse_value_fragment "x"
      p.items[0].invisible?.should == true
    end
  end

  describe "a visible measure rest (Z)" do
    it "knows its measure count" do
      p = parse_value_fragment "Z4"
      p.items[0].measure_count.should == 4
    end
    it "can calculate its note length based on the meter" do
      p = parse_value_fragment "M:C\nZ4[M:3/4]Z2\n"
      p.items[0].length.should == 4
      p.items[2].length.should == Rational(6, 4)
    end
    it "defaults to one measure" do
      p = parse_value_fragment "Z"
      p.items[0].measure_count.should == 1
    end
    it "knows it's visible" do
      p = parse_value_fragment "Z"
      p.items[0].invisible?.should == false
    end
  end

  describe "an invisible measure rest (X)" do
    it "knows its measure count" do
      p = parse_value_fragment "X4"
      p.items[0].measure_count.should == 4
    end
    it "can calculate its note length based on the meter" do
      p = parse_value_fragment "M:C\nX4[M:3/4]X2\n"
      p.items[0].length.should == 4
      p.items[2].length.should == Rational(6, 4)
    end
    it "defaults to one measure" do
      p = parse_value_fragment "X"
      p.items[0].measure_count.should == 1
    end
    it "knows it's invisible" do
      p = parse_value_fragment "X"
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
      p = parse_value_fragment "K:Am clef=bass"
      p.clef.name.should == "bass"
    end
    it "can appear in a V: field" do
      p = parse_value_fragment "V:Bass clef=bass"
      p.voices["Bass"].clef.name.should == "bass"
    end
    it "can appear without 'clef='" do
      p = parse_value_fragment "K:bass"
      p.clef.name.should == "bass"
    end
    it "can have names treble, alto, tenor, bass, perc or none" do
      p = parse_value_fragment "K:treble"
      p.key.clef.name.should == "treble"
      p = parse_value_fragment "K:alto"
      p.key.clef.name.should == "alto"
      p = parse_value_fragment "K:tenor"
      p.key.clef.name.should == "tenor"
      p = parse_value_fragment "K:bass"
      p.key.clef.name.should == "bass"
      p = parse_value_fragment "K:perc"
      p.key.clef.name.should == "perc"
      p = parse_value_fragment "K:clef=none"
      p.key.clef.name.should == "none"
    end
    it "can specify the line on which to draw the clef" do
      p = parse_value_fragment "K:Am clef=bass4"
      p.key.clef.line.should == 4
    end
    it "has default lines for the basic clefs" do
      p = parse_value_fragment "K:C clef=treble"
      p.key.clef.line.should == 2
      p = parse_value_fragment "K:C clef=alto"
      p.key.clef.line.should == 3
      p = parse_value_fragment "K:C clef=tenor"
      p.key.clef.line.should == 4
      p = parse_value_fragment "K:C clef=bass"
      p.key.clef.line.should == 4
    end
    it "can include a 1-octave shift up or down using +8 or -8" do
      p = parse_value_fragment "K:Am clef=bass"
      p.key.clef.octave_shift.should == 0
      p = parse_value_fragment "K:Am clef=alto+8"
      p.key.clef.octave_shift.should == 1
      p = parse_value_fragment "K:Am clef=treble-8"
      p.key.clef.octave_shift.should == -1
    end    
    it "can specify a middle pitch" do
      p = parse_value_fragment "K:C clef=treble middle=d"
      p.key.clef.middle.height.should == 14
      p = parse_value_fragment "K:C treble middle=d"
      p.key.clef.middle.height.should == 14
      p = parse_value_fragment "K:C middle=d"
      p.key.clef.middle.height.should == 14
    end
    it "has default middle pitch for the basic clefs" do
      p = parse_value_fragment "K:C clef=treble"
      p.key.clef.middle.height.should == 11
      p = parse_value_fragment "K:C clef=alto"
      p.key.clef.middle.height.should == 0
      p = parse_value_fragment "K:C clef=tenor"
      p.key.clef.middle.height.should == -3
      p = parse_value_fragment "K:C clef=bass"
      p.key.clef.middle.height.should == -10
      p = parse_value_fragment "K:C clef=none"
      p.key.clef.middle.height.should == 11
    end
    it "can specify a transposition" do
      p = parse_value_fragment "K:C clef=treble transpose=-2"
      p.key.clef.transpose.should == -2
      p = parse_value_fragment "K:C clef=treble t=4"
      p.key.clef.transpose.should == 4
    end
    it "has a default transposition of 0" do
      p = parse_value_fragment "K:C clef=treble"
      p.key.clef.transpose.should == 0
    end
    it "can specify an octave shift with 'octave='" do
      p = parse_value_fragment "K:C clef=treble octave=-2\nc"
      p.key.clef.octave_shift.should == -2
      p.notes[0].pitch.height.should == -12
    end
    it "has a default octave shift of 0" do
      p = parse_value_fragment "K:C clef=treble"
      p.key.clef.octave_shift.should == 0
    end
    it "can specify the number of stafflines" do
      p = parse_value_fragment "K:C clef=treble stafflines=4"
      p.key.clef.stafflines.should == 4
    end
    it "has a default of 5 stafflines" do
      p = parse_value_fragment "K:C clef=treble"
      p.key.clef.stafflines.should == 5
    end
    it "is allowed to use unknown clef names" do
      p = parse_value_fragment "K:C baritone"
      p.key.clef.name.should == 'baritone' 
    end
    it "matches treble clef's line and middle pitch if clef name is unknown" do
      p = parse_value_fragment "K:C baritone"
      p.key.clef.line.should == 2
      p.key.clef.middle.height.should == 11
    end
    it "defaults to treble" do
      p = parse_value_fragment "K:C"
      p.key.clef.name.should == 'treble'
    end
    it "is allowed to use app-specific specifiers" do
      p = parse_value_fragment "K:C clef=perc mozart:noteC=snare-drum"
    end
    it "can place its specifiers in any order" do
      p = parse_value_fragment "K:C middle=d stafflines=3 bass4+8 t=-3"
      p.clef.name.should == 'bass'
      p.clef.middle.note.should == 'D'
      p.clef.stafflines.should == 3
      p.clef.transpose.should == -3
      p.clef.octave_shift.should == 1
    end
    it "can combine octave shifts with octave= and +/-8" do
      p = parse_value_fragment "K: bass+8 octave=-1"
      p.clef.octave_shift.should == 0
    end
  end


    # 4.7 Beams
    # To group notes together under one beam they must be grouped together without spaces. Thus in 2/4, A2BC will produce an eighth note followed by two sixteenth notes under one beam whilst A2 B C will produce the same notes separated. The beam slopes and the choice of upper or lower stems are typeset automatically.
    # Notes that cannot be beamed may be placed next to each other. For example, if L:1/8 then ABC2DE is equivalent to AB C2 DE.
    # Back quotes ` may be used freely between notes to be beamed, to increase legibility. They are ignored by computer programs. For example, A2``B``C is equivalent to A2BC.

  describe "a beam" do
    it "connects adjacent notes" do
      p = parse_value_fragment "abc"
      p.items[0].beam.should == :start
      p.items[1].beam.should == :middle
      p.items[2].beam.should == :end
    end
    it "connects notes separated by backticks" do
      p = parse_value_fragment "a``b"
      p.items[0].beam.should == :start
      p.items[1].beam.should == :end
    end
    it "does not connect notes separated by space" do
      p = parse_value_fragment "ab c"
      p.notes[1].beam.should == :end
      p.notes[2].beam.should == nil
    end
    it "does not connect notes separated by bar lines" do
      p = parse_value_fragment "ab|c"
      p.notes[1].beam.should == :end
      p.notes[2].beam.should == nil
    end
    it "does not connect notes separated by fields" do
      p = parse_value_fragment "ab[L:1/16]c"
      p.notes[1].beam.should == :end
    end
    it "connects notes separated by line continuation" do
      p = parse_value_fragment "ab\\\nc"
      p.notes[1].beam.should == :middle
      p.notes[2].beam.should == :end
    end
    it "does not connect notes separated by space plus line continuation" do
      p = parse_value_fragment "ab \\\nc"
      p.notes[1].beam.should == :end
      p.notes[2].beam.should == nil
    end
    it "does not connect notes separated by line continuation plus space" do
      p = parse_value_fragment "ab\\\n c"
      p.notes[1].beam.should == :end
      p.notes[2].beam.should == nil
    end
    it "does not connect notes that are unbeamable" do
      p = parse_value_fragment "ab2"
      p.notes[0].beam.should == nil
      p.notes[1].beam.should == nil
    end
    it "does not connect notes separated by overlay symbols" do
      p = parse_value_fragment "a&b"
      p.notes[0].beam.should == nil
      p.notes[1].beam.should == nil
    end
    it "does not connect notes separated by rests" do
      p = parse_value_fragment "axb"
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
      p = parse_value_fragment "a|b"
      bar = p.items[1]
      bar.is_a?(BarLine).should == true
      bar.type.should == :thin
    end
    it "can be double" do
      p = parse_value_fragment "a||b"
      p.items.count.should == 3
      bar = p.items[1]
      bar.is_a?(BarLine).should == true
      bar.type.should == :double
    end
    it "can be thin-thick" do
      p = parse_value_fragment "a|]"
      p.items.count.should == 2
      bar = p.items.last
      bar.is_a?(BarLine).should == true
      bar.type.should == :thin_thick
    end
    it "can be thick-thin" do
      p = parse_value_fragment "[|C"
      p.items.count.should == 2
      bar = p.items[0]
      bar.is_a?(BarLine).should == true
      bar.type.should == :thick_thin
    end
    it "can be dotted" do
      p = parse_value_fragment "a.|b"
      p.items.count.should == 3
      bar = p.items[1]
      bar.is_a?(BarLine).should == true
      bar.dotted?.should == true
    end
    it "can be invisible" do
      p = parse_value_fragment "a[|]b"
      p.items.count.should == 3
      bar = p.items[1]
      bar.is_a?(BarLine).should == true
      bar.type.should == :invisible
    end
    it "can repeat to the left" do
      p = parse_value_fragment "|:"
      p.items[0].type.should == :thin
      p.items[0].repeat_before.should == 0
      p.items[0].repeat_after.should == 1
    end
    it "can repeat to the right" do
      p = parse_value_fragment ":|"
      p.items[0].type.should == :thin
      p.items[0].repeat_before.should == 1
      p.items[0].repeat_after.should == 0
    end    
    it "can repeat to the right if it's thin-thick" do
      p = parse_value_fragment ":|]"
      p.items[0].type.should == :thin_thick
      p.items[0].repeat_before.should == 1
      p.items[0].repeat_after.should == 0
    end
    it "can repeat to the left if it's thin-thick" do
      p = parse_value_fragment "[|:"
      p.items[0].type.should == :thick_thin
      p.items[0].repeat_before.should == 0
      p.items[0].repeat_after.should == 1
    end
    it "can indicate multiple repeats" do
      p = parse_value_fragment "::|"
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
      p = parse_value_fragment "abc|[1 abc :|[2 def |]"
      p.items[4].is_a?(VariantEnding).should == true
      p.items[4].range_list.should == [1]
      p.items[9].is_a?(VariantEnding).should == true
      p.items[9].range_list.should == [2]
    end
    it "can be notated with |1 and |2" do 
      p = parse_value_fragment "abc|1 abc:|2 def ||"
      p.items[4].is_a?(VariantEnding).should == true
      p.items[4].range_list.should == [1]
      p.items[9].is_a?(VariantEnding).should == true
      p.items[9].range_list.should == [2]
    end
    it "can be notated with | [1" do
      p = parse_value_fragment "abc| [1 abc :| [2 def |]"
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
      p = parse_value_fragment "[1,3,5-7 abc || [2,4,8 def ||"
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
      p = parse_value_fragment "a a"
      p.items[0].tied_right.should == false
      p.items[1].tied_left.should == false
    end
    it "is indicated by a hyphen" do
      p = parse_value_fragment "a-a"
      p.items[0].tied_right.should == true
      p.items[1].tied_left.should == true
    end
    # TODO convert this to slur
    it "can be used to mark a slur" do
      p = parse_value_fragment "a-b"
      p.items[0].tied_right.should == true
      p.items[1].tied_left.should == true
    end
    it "can operate across spaces" do
      p = parse_value_fragment "a- b"
      p.items[0].tied_right.should == true
      p.items[1].tied_left.should == true
    end
    it "can operate across bar lines" do
      p = parse_value_fragment "a-|b"
      p.items[0].tied_right.should == true
      p.items[2].tied_left.should == true
    end
    it "can operate across fields" do
      p = parse_value_fragment "a-[M:6/8]b"
      p.items[0].tied_right.should == true
      p.items[2].tied_left.should == true
    end
    it "can be dotted" do
      p = parse_value_fragment "a.-b"
      p.items[0].tied_right.should == false
      p.items[0].tied_right_dotted.should == true
      p.items[1].tied_left.should == true
    end
  end

  describe "a slur" do
    it "is indicated with parenthesis" do
      p = parse_value_fragment "d(ab^c)d"
      p.items[1].start_slur.should == 1
      p.items[3].end_slur.should == 1
    end
    it "can be nested" do
      p = parse_value_fragment "d(a(b^c))"
      p.items[1].start_slur.should == 1
      p.items[2].start_slur.should == 1
      p.items[3].end_slur.should == 2
    end
    it "can exist on a single note" do
      p = parse_value_fragment "d(a)b^c"
      p.items[1].start_slur.should == 1
      p.items[1].end_slur.should == 1
    end
    it "can operate across spaces" do
      p = parse_value_fragment "(a b c)"
      p.items[0].start_slur.should == 1
      p.items[2].end_slur.should == 1
    end
    it "can operate across bar lines" do
      p = parse_value_fragment "(ab|c)"
      p.items[0].start_slur.should == 1
      p.items[3].end_slur.should == 1
    end
    it "can operate across fields" do
      p = parse_value_fragment "(ab[M:6/8]c)"
      p.items[0].start_slur.should == 1
      p.items[3].end_slur.should == 1
    end
    it "can slur a single note" do
      p = parse_value_fragment "(a)"
      p.items[0].start_slur.should == 1
      p.items[0].end_slur.should == 1
    end
    it "can be dotted" do
      p = parse_value_fragment "(a.(bc))"
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
      p = parse_value_fragment "{gege}B"
      p.notes[0].grace_notes.type.should == :appoggiatura
    end
    it "can indicate an acciaccatura" do
      p = parse_value_fragment "{/ge4d}B"
      p.notes[0].grace_notes.type.should == :acciaccatura
    end
    it "has notes" do
      p = parse_value_fragment "{gege}B"
      p.notes[0].grace_notes.notes.count.should == 4
      p.notes[0].grace_notes.notes[0].pitch.note.should == "G"
    end
    it "applies the current key to the notes" do
      p = parse_value_fragment "[K:HP]{gf}B"
      p.notes[0].grace_notes.notes[1].pitch.height.should == 18 # F sharp
    end
    it "can include note length markers" do
      p = parse_value_fragment "{a3/2b/}B"
    end
    it "is independent of the unit note length" do
      p = parse_value_fragment "{a3/2b/}B"
      p.notes[0].length.should == Rational(1, 8)
      p.notes[0].grace_notes.notes[0].length.should == Rational(3, 2)
      p.notes[0].grace_notes.notes[1].length.should == Rational(1, 2)
    end
    it "can include broken rhythm markers" do
      p = parse_value_fragment "{a>b}B"
      p.notes[0].grace_notes.notes[0].length.should == Rational(3, 2)
      p.notes[0].grace_notes.notes[1].length.should == Rational(1, 2)
    end
    it "is transparent to the broken rhythm construct" do
      p = parse_value_fragment "B{ab}>A"
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
      p = parse_value_fragment "[L:1] [M:C] (2abc [M:3/4] (2abc"
      p.notes[0].tuplet_ratio.should == Rational(3, 2)
      p.notes[0].length.should == Rational(3, 2)
      p.notes[1].length.should == Rational(3, 2)
      p.notes[2].length.should == 1
      p.notes[3].length.should == Rational(3, 2)
      p.notes[4].length.should == Rational(3, 2)
      p.notes[5].length.should == 1
    end

    it "can be inspected" do
      p = parse_value_fragment "[L:1] [M:C] (2abc [M:3/4] (2abc"
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
      p = parse_value_fragment "[L:1/8] (2abc [L:1/4] (2abc"
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
      p = parse_value_fragment "[L:1] [M:C] (3abcd [M:3/4] (3abcd"
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
      p = parse_value_fragment "[L:1] [M:C] (4abcde [M:3/4] (4abcde"
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
      p = parse_value_fragment "[L:1] [M:C] (5abcdef"
      p.notes[0].length.should == Rational(2, 5)
      p.notes[1].length.should == Rational(2, 5)
      p.notes[2].length.should == Rational(2, 5)
      p.notes[3].length.should == Rational(2, 5)
      p.notes[4].length.should == Rational(2, 5)
      p.notes[5].length.should == 1
    end
    
    it "uses (5 to mean 5 notes in the time of 3, if meter is compound" do
      p = parse_value_fragment "[L:1] [M:6/8] (5abcdef"
      p.notes[0].length.should == Rational(3, 5)
      p.notes[1].length.should == Rational(3, 5)
      p.notes[2].length.should == Rational(3, 5)
      p.notes[3].length.should == Rational(3, 5)
      p.notes[4].length.should == Rational(3, 5)
      p.notes[5].length.should == 1
    end

    it "uses (6 to mean 6 notes in the time of 2" do
      p = parse_value_fragment "[L:1] [M:C] (6 abc abc d [M:6/8] (6 abc abc d"
      p.notes[5].length.should == Rational(2, 6)
      p.notes[6].length.should == 1
      p.notes[12].length.should == Rational(2, 6)
      p.notes[13].length.should == 1
    end

    it "uses (6 to mean 6 notes in the time of 2" do
      p = parse_value_fragment "[L:1] [M:C] (6 abc abc d [M:6/8] (6 abc abc d"
      p.notes[5].length.should == Rational(2, 6)
      p.notes[6].length.should == 1
      p.notes[12].length.should == Rational(2, 6)
      p.notes[13].length.should == 1
    end
    
    it "uses (7 to mean 7 notes in the time of 2 (or 3 for compound meter)" do
      p = parse_value_fragment "[L:1] [M:C] (7 abcd abc d [M:6/8] (7 abcd abc d"
      p.notes[6].length.should == Rational(2, 7)
      p.notes[7].length.should == 1
      p.notes[14].length.should == Rational(3, 7)
      p.notes[15].length.should == 1
    end
    
    it "uses (8 to mean 8 notes in the time of 3" do
      p = parse_value_fragment "[L:1] [M:C] (8 abcd abcd e [M:6/8] (8 abcd abcd e"
      p.notes[7].length.should == Rational(3, 8)
      p.notes[8].length.should == 1
      p.notes[16].length.should == Rational(3, 8)
      p.notes[17].length.should == 1
    end
    
    it "uses (9 to mean 9 notes in the time of 2 (or 3 for compound meter)" do
      p = parse_value_fragment "[L:1] [M:C] (9 abcde abcd e [M:6/8] (9 abcde abcd e"
      p.notes[8].length.should == Rational(2, 9)
      p.notes[9].length.should == 1
      p.notes[18].length.should == Rational(3, 9)
      p.notes[19].length.should == 1
    end
    
    it "uses the form (p:q:r to mean p notes in the time of q for r notes" do
      p = parse_value_fragment "[L:1] (3:4:6 abc abc d"
      p.notes[5].length.should == Rational(4, 3)
      p.notes[6].length.should == 1
    end

    it "uses the form (p:q to mean p notes in the time of q for p notes" do
      p = parse_value_fragment "[L:1] (3:4 abc d"
      p.notes[2].length.should == Rational(4, 3)
      p.notes[3].length.should == 1
    end

    it "treats the form (p:q: as a synonym for (p:q" do
      p = parse_value_fragment "[L:1] (3:4: abc d"
      p.notes[2].length.should == Rational(4, 3)
      p.notes[3].length.should == 1
    end

    it "uses the form (p::r to mean p notes in the time of 2 for r notes with simple meter" do
      p = parse_value_fragment "[L:1] [M:C] (3::4 abcd e"
      p.notes[3].length.should == Rational(2, 3)
      p.notes[4].length.should == 1
    end

    it "uses the form (p::r to mean p notes in the time of 2 for r notes with compound meter" do
      p = parse_value_fragment "[L:1] [M:6/8] (2::4 abcd e"
      p.notes[3].length.should == Rational(3, 2)
      p.notes[4].length.should == 1
    end

    it "treats the form (p:: as a synonym for (p" do
      p = parse_value_fragment "[L:1] [M:C] (5:: abcde f [M:6/8] (5:: abcde f"
      p.notes[4].length.should == Rational(2, 5)
      p.notes[5].length.should == 1
      p.notes[10].length.should == Rational(3, 5)
      p.notes[11].length.should == 1
    end

    it "treats the form (p: as a synonym for (p" do
      p = parse_value_fragment "[L:1] [M:C] (5: abcde f [M:6/8] (5: abcde f"
      p.notes[4].length.should == Rational(2, 5)
      p.notes[5].length.should == 1
      p.notes[10].length.should == Rational(3, 5)
      p.notes[11].length.should == 1
    end

    it "can operate on notes of different lengths" do
      p = parse_value_fragment "[L:1] [M:C] (3 D3EF2"
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
      p = parse_value_fragment ".a ~b Hc Ld Me Of Pg Sa Tb uC vD"
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
      p = parse_value_fragment "!trill! A"
      p.notes[0].decorations[0].symbol.should == "trill"
    end
    it "can be applied to chords" do
      p = parse_value_fragment "!f! [CGE]"
      p.notes[0].decorations[0].symbol.should == "f"
    end
    it "can be applied to bar lines" do
      p = parse_value_fragment "abc !fermata! |"
      p.items[3].decorations[0].symbol.should == "fermata"
    end
    it "can be applied to spacers" do
      p = parse_value_fragment "abc !fermata! y"
      p.items[3].decorations[0].symbol.should == "fermata"
    end
    it "can be one of several applied to the same note" do
      p = parse_value_fragment "!p! !trill! .a"
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

    it "aligns symbols to notes" do
      p = parse_value_fragment(['   CDEF    | G```AB`c     c',
                          's: "^slow" | u   ** !fff! "Gm"'].join("\n"))
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

    it "aligns from the first note of the voice if there is no previous s: field" do
      p = parse_value_fragment "[V:1]G,G,G,A,[V:2]GCEA\ns:.Tuv"
      p.notes[0].decorations.should == []
      p.notes[1].decorations.should == []
      p.notes[2].decorations.should == []
      p.notes[3].decorations.should == []
      p.all_notes[4].decorations[0].symbol.should == "staccato"
      p.all_notes[5].decorations[0].symbol.should == "trill"
      p.all_notes[6].decorations[0].symbol.should == "upbow"
      p.all_notes[7].decorations[0].symbol.should == "downbow"
    end

    it "aligns from the first note after the notes aligned to the previous w: field" do
      p = parse_value_fragment "G \ns:. u v \nA\ns: T"
      p.notes[1].decorations[0].symbol.should == "trill"
    end

    it "reaches back across linebreaks" do
      p = parse_value_fragment "C D E F|\nG A B c|\ns: u . . . . . . v"
      p.notes[0].decorations[0].symbol.should == "upbow"
      p.notes[7].decorations[0].symbol.should == "downbow"
    end

    it "ignores excess syllables" do
      p = parse_value_fragment "GC\ns:T u v .\nEA2"
      p.notes[0].decorations[0].symbol.should == "trill"
      p.notes[1].decorations[0].symbol.should == "upbow"
      p.notes[2].decorations.should == []
      p.notes[3].decorations.should == []
    end
    
    it "can explicitly blank symbols from notes" do
      p = parse_value_fragment "C D E F|\ns: . . . u\nG G G G|\ns:\nF E F C|\ns: v . . ."
      p.notes[3].decorations[0].symbol.should == "upbow"
      p.notes[4].decorations.should == []
      p.notes[7].decorations.should == []
      p.notes[8].decorations[0].symbol.should == "downbow"
    end
    
    it "does not match symbols to grace notes" do
      p = parse_value_fragment "{gege}GCAE\ns:T u v ."
      p.notes[0].grace_notes.notes[0].decorations.should == []
      p.notes[0].decorations[0].symbol.should == "trill"
    end

    it "does not match symbols to rests" do
      p = parse_value_fragment "GCEz4A4\ns: Tuv."
      p.notes[3].decorations.should == []
      p.notes[4].decorations[0].symbol.should == "staccato"
    end

    it "does not match symbols to spacers" do
      p = parse_value_fragment "GCEyA4\ns: Tuv."
      p.items[3].decorations.should == []
      p.items[4].decorations[0].symbol.should == "staccato"
    end

    it "aligns symbols separately to tied notes" do
      p = parse_value_fragment "GCE-EA\ns: Tuv."
      p.notes[3].tied_left.should == true
      p.notes[3].pitch.note.should == "E"
      p.notes[3].decorations[0].symbol.should == "staccato"
      p.notes[4].decorations.should == []
    end

    it "aligns symbols separately to slurred notes" do
      p = parse_value_fragment "GC(EA)g\ns: Tuv."
      p.notes[3].end_slur.should > 0
      p.notes[3].pitch.note.should == "A"
      p.notes[3].decorations[0].symbol.should == "staccato"
      p.notes[4].decorations.should == []
    end
    
    it "stacks symbols with consecutive s: lines" do
      p = parse_value_fragment "GCEA\ns: Tu \ns: v."
      p.notes[0].decorations[0].symbol.should == "trill"
      p.notes[1].decorations[0].symbol.should == "upbow"
      p.notes[0].decorations[1].symbol.should == "downbow"
      p.notes[1].decorations[1].symbol.should == "staccato"
      p.notes[2].decorations.should == []
      p.notes[3].decorations.should == []
    end

    it "stacks symbols starting just after the previous s: line" do
      p = parse_value_fragment "ABC\ns:...\nGCEA\ns: Tu \ns: v."
      p.notes[0].decorations[0].symbol.should == "staccato"
      p.notes[0].decorations.count.should == 1
      p.notes[3].decorations[0].symbol.should == "trill"
      p.notes[3].decorations[1].symbol.should == "downbow"
    end

    it "does not stack symbols when continuing the s: line with +:" do
      p = parse_value_fragment "GCEA\ns: Tu \n+: v."
      p.notes[0].decorations[0].symbol.should == "trill"
      p.notes[1].decorations[0].symbol.should == "upbow"
      p.notes[2].decorations[0].symbol.should == "downbow"
      p.notes[3].decorations[0].symbol.should == "staccato"
    end

    it "skips notes with *" do
      p = parse_value_fragment "acddc\ns:*u ** v"
      p.notes[0].decorations.should == []
      p.notes[1].decorations[0].symbol.should == "upbow"
      p.notes[2].decorations.should == []
      p.notes[3].decorations.should == []
      p.notes[4].decorations[0].symbol.should == "downbow"
    end

    it "advances to the next bar with |" do
      p = parse_value_fragment "abc|def\ns:u|v"
      p.notes[0].decorations[0].symbol.should == "upbow"
      p.notes[1].decorations.should == []
      p.notes[2].decorations.should == []
      p.notes[3].decorations[0].symbol.should == "downbow"
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
      p = parse_value_fragment("[U:t=!halftrill!] ta")
      p.notes[0].decorations[0].symbol.should == 'halftrill'
    end
    it "can redefine one of the predefined shortcuts" do
      p = parse_value_fragment("[U:T=!halftrill!] Ta")
      p.notes[0].decorations[0].symbol.should == 'halftrill'
    end
    it "can define a shortcut in the tune header" do
      p = parse_value_fragment("U:t=!halftrill!\nK:C\nta")
      p.notes[0].decorations[0].symbol.should == 'halftrill'
    end
    it "can define a shortcut in the file header" do
      p = parse_value("U:t=!halftrill!\n\nX:1\nT:T\nK:C\nta")
      p.tunes[0].notes[0].decorations[0].symbol.should == 'halftrill'
    end
    it "can be redefined after being defined once" do
      p = parse_value("U:t=!halftrill!\n\nX:1\nT:T\nK:C\n[U:t=!headbutt!]ta")
      p.tunes[0].notes[0].decorations[0].symbol.should == 'headbutt'
      p = parse_value("U:t=!halftrill!\n\nX:1\nT:T\nU:t=!headbutt!\nK:C\nta")
      p.tunes[0].notes[0].decorations[0].symbol.should == 'headbutt'
    end
    it "can define annotations as well as decorations" do
      p = parse_value("U:t=\"^look up here\"\n\nX:1\nT:T\nK:C\nta")
      p.tunes[0].notes[0].annotations[0].text.should == 'look up here'
      p.tunes[0].notes[0].annotations[0].placement.should == :above
    end
    it "can have the same value as another" do
      p = parse_value("U:T=!thrill!  X:1 T:T U:U=!thrill! K:C TaUb".gsub(' ', "\n"))
      p.tunes[0].notes[0].decorations[0].symbol.should == 'thrill'
      p.tunes[0].notes[1].decorations[0].symbol.should == 'thrill'
    end
    it "can be de-assigned with !nil! or !none!" do
      p = parse_value_fragment(".a[U:.=!nil!].b ua[U:u=!none!]ub")
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
      p = parse_value_fragment "[CEG]"
      p.notes[0].is_a?(Chord).should == true
      p.notes[0].notes.count.should == 3
      p.notes[0].notes[0].pitch.height.should == 0
      p.notes[0].notes[1].pitch.height.should == 4
      p.notes[0].notes[2].pitch.height.should == 7
    end
    it "can be beamed" do
      p = parse_value_fragment "[d2f2][ce][df] [ce]"
      p.notes[0].beam.should == nil
      p.notes[1].beam.should == :start
      p.notes[2].beam.should == :end
      p.notes[3].beam.should == nil
    end
    it "has its duration determined by the first note if notes have inconsistent lengths" do
      p = parse_value_fragment "[d2ag/]"
      p.notes[0].length.should == Rational(1, 4)
    end
    it "cannot take an accidental" do
      fail_to_parse_fragment "^[CEG]"
      fail_to_parse_fragment "_[CEG]"
      parse_fragment "[C_EG]"
    end
    it "can have decorations on the inside notes" do
      p = parse_value_fragment "[.CuE!hoohah!G]"
      p.items[0].notes[0].annotations[0] == 'staccato'
      p.items[0].notes[1].annotations[0] == 'upbow'
      p.items[0].notes[2].annotations[0] == 'hoohah'
    end
    it "multiplies inner length modifiers by outer" do
      p = parse_value_fragment "L:1\n[C2E2G2]3/"
      p.items[0].notes[0].length.should == 3
    end
    it "obeys key signatures" do
      p = parse_value_fragment "K:D\n[DFA]"
      p.items[0].notes[1].pitch.height.should == 6      
    end
    it "obeys measure accidentals" do
      p = parse_value_fragment "^F[DFA]|[DFA]"
      p.items[1].notes[1].pitch.height.should == 6      
      p.items[3].notes[1].pitch.height.should == 5      
    end
    it "creates measure accidentals" do
      p = parse_value_fragment "[D^FA]F|F"
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
      p = parse_value_fragment '"Am7"A2D2'
      p.items[0].chord_symbol.text.should == "Am7"
    end
    it "can include a bass note" do
      p = parse_value_fragment '"C/E"G'
      p.items[0].chord_symbol.text.should == "C/E"
    end
    it "can include an alternate chord" do
      p = parse_value_fragment '"G(Em/G)"G'
      p.items[0].chord_symbol.text.should == "G(Em/G)"
    end
    # TODO parse the chord symbols for note, type, bassnote etc
  end


  # 4.19 Annotations
  # General text annotations can be added above, below or on the staff in a similar way to chord symbols. In this case, the string within double quotes is preceded by one of five symbols ^, _, <, > or @ which controls where the annotation is to be placed; above, below, to the left or right respectively of the following note, rest or bar line. Using the @ symbol leaves the exact placing of the string to the discretion of the interpreting program. These placement specifiers distinguish annotations from chord symbols, and should prevent programs from attempting to play or transpose them. All text that follows the placement specifier is treated as a text string.
  # Where two or more annotations with the same placement specifier are placed consecutively, e.g. for fingerings, the notation program should draw them on separate lines, with the first listed at the top.
  # Example: The following annotations place the note between parentheses.
  # "<(" ">)" C

  describe "an annotation" do
    it "can be placed above a note" do
      p = parse_value_fragment '"^above"c'
      p.items[0].annotations[0].placement.should == :above
      p.items[0].annotations[0].text.should == "above"
    end
    it "can be placed below a note" do
      p = parse_value_fragment '"_below"c'
      p.items[0].annotations[0].placement.should == :below
      p.items[0].annotations[0].text.should == "below"
    end
    it "can be placed to the left and right of a note" do
      p = parse_value_fragment '"<(" ">)" c'
      p.items[0].annotations[0].placement.should == :left
      p.items[0].annotations[0].text.should == "("
      p.items[0].annotations[1].placement.should == :right
      p.items[0].annotations[1].text.should == ")"
    end
    it "can have unspecified placement" do
      p = parse_value_fragment '"@wherever" c'
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

  describe "the order of abc constructs" do
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



