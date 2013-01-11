# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('.')
require 'spec/parser/spec_helper'

  # 7. Multiple voices
  # VOLATILE: Multi-voice music is under active review, with discussion about control voices and interaction between P:, V: and T: fields. It is intended that the syntax will be finalised in abc 2.2.
  # The V: field allows the writing of multi-voice music. In multi-voice abc tunes, the tune body is divided into several voices, each beginning with a V: field. All the notes following such a V: field, up to the next V: field or the end of the tune body, belong to the voice.
  # The basic syntax of the field is:
  # V:ID
  # where ID can be either a number or a string, that uniquely identifies the voice in question. When using a string, only the first 20 characters of it will be distinguished. The ID will not be printed on the staff; it's only function is to indicate, throughout the abc tune, which music line belongs to which voice.
  # Example:
  # X:1
  # T:Zocharti Loch
  # C:Louis Lewandowski (1821-1894)
  # M:C
  # Q:1/4=76
  # %%score (T1 T2) (B1 B2)
  # V:T1           clef=treble-8  name="Tenore I"   snm="T.I"
  # V:T2           clef=treble-8  name="Tenore II"  snm="T.II"
  # V:B1  middle=d clef=bass      name="Basso I"    snm="B.I"
  # V:B2  middle=d clef=bass      name="Basso II"   snm="B.II"
  # K:Gm
  # %            End of header, start of tune body:
  # % 1
  # [V:T1]  (B2c2 d2g2)  | f6e2      | (d2c2 d2)e2 | d4 c2z2 |
  # [V:T2]  (G2A2 B2e2)  | d6c2      | (B2A2 B2)c2 | B4 A2z2 |
  # [V:B1]       z8      | z2f2 g2a2 | b2z2 z2 e2  | f4 f2z2 |
  # [V:B2]       x8      |     x8    |      x8     |    x8   |
  # % 5
  # [V:T1]  (B2c2 d2g2)  | f8        | d3c (d2fe)  | H d6    ||
  # [V:T2]       z8      |     z8    | B3A (B2c2)  | H A6    ||
  # [V:B1]  (d2f2 b2e'2) | d'8       | g3g  g4     | H^f6    ||
  # [V:B2]       x8      | z2B2 c2d2 | e3e (d2c2)  | H d6    ||
  # This layout closely resembles printed music, and permits the corresponding notes on different voices to be vertically aligned so that the chords can be read directly from the abc. The addition of single remark lines "%" between the grouped staves, indicating the bar numbers, also makes the source more legible.
  # V: can appear both in the body and the header. In the latter case, V: is used exclusively to set voice properties. For example, the name property in the example above, specifies which label should be printed on the first staff of the voice in question. Note that these properties may be also set or changed in the tune body. The V: properties are fully explained below.
  # Please note that the exact grouping of voices on the staff or staves is not specified by V: itself. This may be specified with the %%score stylesheet directive. See voice grouping for details.
  # For playback, see instrumentation directives for details of how to assign a General MIDI instrument to a voice using a %%MIDI stylesheet directive.
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
  # In the example above, each V: label occurs only once, and the complete part for that voice follows. The output of tune X:2 will be exactly the same as the output of tune X:1; the source code of X:1, however, is much easier to read.

  describe "a voice field in the tune body" do
    it "divides the tune into several voices" do
      p = parse_value_fragment "V:A\nV:B\n[V:A]abc\n[V:B]def"
      a = p.voices['A']
      b = p.voices['B']
      a.notes[0].pitch.note.should == "A"
      a.notes[1].pitch.note.should == "B"
      a.notes[2].pitch.note.should == "C"
      b.notes[0].pitch.note.should == "D"
      b.notes[1].pitch.note.should == "E"
      b.notes[2].pitch.note.should == "F"
    end
    it "works even if you don't declare voices in header" do
      p = parse_value_fragment "K:C\nV:A\nabc\nV:B\ndef"
      a = p.voices['A']
      b = p.voices['B']
      a.notes[0].pitch.note.should == "A"
      a.notes[1].pitch.note.should == "B"
      a.notes[2].pitch.note.should == "C"
      b.notes[0].pitch.note.should == "D"
      b.notes[1].pitch.note.should == "E"
      b.notes[2].pitch.note.should == "F"
    end
    it "only pays attention to the 1st 20 characters of the id" do
      p = parse_value_fragment "V:1234567890123456789012345"
      p.voices['1234567890123456789012345'].should == nil
      p.voices['12345678901234567890'].should_not == nil
    end
  end


  # 7.1 Voice properties
  # VOLATILE: See above.
  # V: fields can contain voice specifiers such as name, clef, and so on. For example,
  # V:T name="Tenor" clef=treble-8
  # indicates that voice T will be drawn on a staff labelled Tenor, using the treble clef with a small 8 underneath. Player programs will transpose the notes by one octave. Possible voice definitions include:
  # name="voice name" - the voice name is printed on the left of the first staff only. The characters \n produce a newline in the output.
  # subname="voice subname" - the voice subname is printed on the left of all staves but the first one.
  # stem=up/down - forces the note stem direction.
  # clef= - specifies a clef; see clefs and transposition for details.
  # The name specifier may be abbreviated to nm=. The subname specifier may be abbreviated to snm=.
  # Applications may implement their own specifiers, but must gracefully ignore specifiers they don't understand or implement. This is required for portability of abc files between applications.

  describe "a V: (voice) field in the tune header" do
    it "can include a name and subname" do
      p = parse_value_fragment 'V:Ma tenor name="Mama" subname="M"'
      p.voices['Ma'].name.should == 'Mama'
      p.voices['Ma'].subname.should == 'M'
    end
    it "can abbreviate name and subname with nm and snm" do
      p = parse_value_fragment 'V:Da snm="D" nm="Daddy" bass'
      p.voices['Da'].name.should == 'Daddy'
      p.voices['Da'].subname.should == 'D'
    end
    it "can specify the stem direction" do
      p = parse_value_fragment 'V:T1'
      p.voices['T1'].stem.should == nil
      p = parse_value_fragment 'V:T1 stem=up'
      p.voices['T1'].stem.should == :up
      p = parse_value_fragment 'V:T1 stem=down'
      p.voices['T1'].stem.should == :down
    end
    it "can include clef specifiers" do
      p = parse_value_fragment 'V:T1 nm="Tenore I" snm="T.I" middle=d stafflines=3 bass4+8 t=-3'
      clef = p.voices['T1'].clef
      clef.name.should == 'bass'
      clef.middle.note.should == 'D'
      clef.stafflines.should == 3
      clef.transpose.should == -3
      clef.octave_shift.should == 1
    end
  end


  # 7.2 Breaking lines
  # VOLATILE: See above. In particular the following may be relaxed with the introduction of a control voice.
  # The rules for typesetting line-breaks in multi-voice abc tunes are the same as for single voice music although additionally a line-break in one voice must be matched in the other voices. See the example tune Canzonetta.abc.

  # ^^ no tests
  # TODO enforce linebreak matching?


  # 7.3 Inline fields
  # VOLATILE: See above.
  # To avoid ambiguity, inline fields that specify music properties should be repeated in every voice to which they apply.
  # Example:
  # [V:1] C4|[M:3/4]CEG|Gce|
  # [V:2] E4|[M:3/4]G3 |E3 |

  # ^^ no tests
  # TODO some sort of consistency check for voices

  describe "voice support" do
    it "reports when there is more than one voice" do
      p = parse_value_fragment "abc"
      p.many_voices?.should == false
      p = parse_value_fragment "V:1\nV:2\n[V:1]abc"
      p.many_voices?.should == true
    end
    it "resets key when new voice starts" do
      p = parse_value_fragment "[V:1]b[K:F]b[V:2]b[K:F]b"
      v1 = p.voices['1']
      v2 = p.voices['2']
      v1.notes[0].pitch.height.should == 23 # B
      v1.notes[1].pitch.height.should == 22 # B flat
      v2.notes[0].pitch.height.should == 23
      v2.notes[1].pitch.height.should == 22
    end
    it "retains key change when voice comes back" do
      p = parse_value_fragment "[V:1]b[K:F]b[V:2]b[K:F]b[V:1]b[K:C]b"
      v1 = p.voices['1']
      v1.notes[2].pitch.height.should == 22 # B flat
      v1.notes[3].pitch.height.should == 23 # B
    end
    it "resets meter when new voice starts" do
      p = parse_value_fragment "M:C\n[V:1]Z4[M:3/4]Z4[V:2]Z4[M:3/4]Z4"
      v1 = p.voices['1']
      v2 = p.voices['2']
      v1.notes[0].note_length.should == 4
      v1.notes[1].note_length.should == 3
      v2.notes[0].note_length.should == 4
      v2.notes[1].note_length.should == 3
    end
    it "retains meter change when voice comes back" do
      p = parse_value_fragment "M:C\n[V:1]Z4[M:3/4]Z4[V:2]Z4[M:3/4]Z4[V:1]Z4[M:C]Z4"
      v1 = p.voices['1']
      v1.notes[2].note_length.should == 3
      v1.notes[3].note_length.should == 4
    end
    it "resets unit note length when new voice starts" do
      p = parse_value_fragment "[V:1]a[L:1/4]b[V:2]a[L:1/4]b"
      v1 = p.voices['1']
      v2 = p.voices['2']
      v1.notes[0].note_length.should == Rational(1, 8)
      v1.notes[1].note_length.should == Rational(1, 4)
      v2.notes[0].note_length.should == Rational(1, 8)
      v2.notes[1].note_length.should == Rational(1, 4)
    end
    it "retains unit note length change when voice comes back" do
      p = parse_value_fragment "[V:1]a[L:1/4]b[V:2]a[L:1/4]b[V:1]a[L:1/16]b"
      v1 = p.voices['1']
      v1.notes[2].note_length.should == Rational(1, 4)
      v1.notes[3].note_length.should == Rational(1, 16)
    end
    it "applies the voice's clef to notes" do
      p = parse_value_fragment "V:1 bass\nK:C\n[V:1]a"
      p.notes[0].pitch.clef.name.should == "bass"
    end
    it "overrides the tune's clef with the voice's" do
      p = parse_value_fragment "V:1 bass\nK:C alto\n[V:1]a"
      p.notes[0].pitch.clef.name.should == "bass"
    end
    it "uses the tune's clef if the voice doesn't have one" do
      p = parse_value_fragment "V:1\nK:C alto\n[V:1]a"
      p.notes[0].pitch.clef.name.should == "alto"
    end
    it "uses first voice if you don't specify which voice" do
      p = parse_value_fragment "[V:1]a[V:2]b[V:1]a[V:2]b"
      p.notes.should == p.voices["1"].notes
    end
    it "uses a default voice if no voices are specified in the music code" do
      p = parse_value_fragment "abc"
      p.voices[""].items.should == p.items
    end
  end


  # 7.4 Voice overlay
  # VOLATILE: See above.
  # The & operator may be used to temporarily overlay several voices within one measure. Each & operator sets the time point of the music back by one bar line, and the notes which follow it form a temporary voice in parallel with the preceding one. This may only be used to add one complete bar's worth of music for each &.
  # Example:
  # A2 | c d e f g  a  &\
  #      A A A A A  A  &\
  #      F E D C B, A, |]
  # Words in w: lines (and symbols in s: lines) are matched to the corresponding notes as per the normal rules for lyric alignment (see lyrics), disregarding any overlay in the accompanying music code.
  # Example:
  #     g4 f4 | e6 e2 |
  # && (d8    | c6) c2|
  # w: ha-la-| lu-yoh
  # +: lu-   |   -yoh
  # This revokes the abc 2.0 usage of & in w: and s: lines, which is now deprecated (see disallowed).

  describe "a voice overlay" do
    it "can be created with the & operator" do
      p = parse_value_fragment "|a b c & A B C|"
      p.measures[0].overlays?.should == true
      p.measures[0].overlays.count.should == 1
      p.measures[0].notes[0].pitch.height.should == 21
      p.measures[0].overlays[0].notes[0].pitch.height.should == 9
    end
    it "can overlay multiple bars with multiple &s" do
      p = parse_value_fragment "|a b | c2 | && | A B | C2 |"
      p.measures.count.should == 2
      p.measures[0].overlays?.should == true
      p.measures[0].overlays.count.should == 1
      p.measures[0].notes[0].pitch.height.should == 21
      p.measures[0].overlays[0].notes[0].pitch.height.should == 9
      p.measures[1].overlays?.should == true
      p.measures[1].overlays.count.should == 1
      p.measures[1].notes[0].pitch.height.should == 12
      p.measures[1].overlays[0].notes[0].pitch.height.should == 0
    end
    it "is aligns notes with lyrics in whatever sequence they occur in the music code" do
      p = parse_value_fragment "g4 f4|e6 e2| && (d8|c6)c2|\nw:ha-la-|lu-yoh \n+: lu-   |   -yoh"
      p.measures[0].notes[0].lyric.text.should == "ha"
      p.measures[0].notes[1].lyric.text.should == "la"
      p.measures[1].notes[0].lyric.text.should == "lu"
      p.measures[1].notes[1].lyric.text.should == "yoh"
      p.measures[0].overlay.notes[0].lyric.text.should == "lu"
      p.measures[1].overlay.notes[0].lyric.should == nil
      p.measures[1].overlay.notes[1].lyric.text.should == "yoh"
    end
  end

  describe "measure support" do
    it "allows bars[] as a synonym for measures[]" do
      p = parse_value_fragment "|a b c & A B C|"
      p.bars.should == p.measures
      p.voices[""].bars.should == p.voices[""].measures
    end
  end


