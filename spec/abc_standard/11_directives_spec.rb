# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('.')
require 'spec/abc_standard/spec_helper'

# 11. Stylesheet directives and pseudo-comments
# 11.0 Introduction to directives

# 11.0.1 Disclaimer
# In the early days of abc, pseudo-comments (lines starting with %%) were introduced as a means of adding software-specific information and formatting instructions into abc files; because they started with a % symbol software that didn't recognise them would ignore them as a comment.
# In a valiant effort, abc 2.0 made an attempt to standardise these pseudo-comments with the introduction stylesheet directives and the abc stylesheet specification. This was described as "not part of the ABC specification itself" but as "an additional standard" containing directives to control how the content and structural information described by the abc code "is to be actually rendered, for example by a typesetting or player program".
# Unfortunately, however, there are a very large number of pseudo-comment directives and not all of them are well-defined. Furthermore, some directives, in particular the text directives and accidental directives, actually contain content and / or structural information (as opposed to rendering instructions).
# Abc 2.1 has stepped away from this approach somewhat.
# The pseudo-comments are still very much accepted as a way for developers to introduce experimental features and software-specific formatting instructions. However, when a directive gains acceptance, either by being implemented in more than one piece of software, or by its use in a substantial body of tunes, the aim is that the usage will be standardised and adopted in the standard and the I: instruction form recommended in place of the %% pseudo-comment form.
# In particular, it is intended that abc 2.3 will address markup and embedding and at that point a number of the text-based directives, together with other widely accepted forms, will be formally incorporated.
# For the moment, section 11 is retained mostly unchanged from abc 2.0 (save for typo corrections) but, as a result of the foregoing, the whole of section 11 and all stylesheet directives should regarded as VOLATILE.

# 11.0.2 Stylesheet directives
# A stylesheet directive is a line that starts with %%, followed by a directive that gives instructions to typesetting or player programs.
# Examples:
# %%papersize A4
# %%newpage
# %%setbarnb 10
# Alternatively, any stylesheet directive may be written as an I:instruction field although this is not recommended for usages which have not been standardised (i.e. it is not recommended for any directives described in section 11).
# Examples: Not recommended.
# I:papersize A4
# I:newpage
# I:setbarnb 10
# Inline field notation may be used to place a stylesheet directive in the middle of a line of music:
# Example:
# CDEFG|[I:setbarnb 10]ABc
# If a program doesn't recognise a stylesheet directive, it should just ignore it.
# It should be stressed that the stylesheet directives are not formally part of the abc standard itself. Furthermore, the list of possible directives is long and not standardised. They are provided by a variety of programs for specifying layout, text annotations, fonts, spacings, voice instruments, transposition and other details.
# Strictly speaking, abc applications don't have to conform to the same set of stylesheet directives. However, it is desirable that they do in order to make abc files portable between different computer systems.

describe "a stylesheet directive" do
  it "is processed the same as an instruction field" do
    p = parse_fragment "%%papersize A4"
    p.instructions['papersize'].should == 'A4'
  end
  it "is differentiated from instruction fields by the identifier '%'" do
    p = parse_fragment "%%papersize A4"
    p.header.fields[0].type.should == :instruction
    p.header.fields[0].identifier.should == "%"
  end
  it "can appear inside a tune" do
    p = parse_fragment "abc\n%%newpage\ndef"
    p.items[3].type.should == :instruction
    p.items[3].directive.should == "newpage"
  end
  it "cannot appear inline" do
    fail_to_parse_fragment "abc %%newpage\ndef"
  end
  it "can be expressed in I: notation for inline use" do
    p = parse_fragment "abc[I:newpage]def"
    p.items[3].type.should == :instruction
    p.items[3].directive.should == "newpage"
  end
end


# 11.1 Voice grouping
# VOLATILE: This section is under review as part of the general discussion about multiple voices for abc 2.2. See also the section 11 disclaimer.
# Basic syntax:
# %%score <voice-id1> <voice-id2> ... <voice-idn>
# The score directive specifies which voices should be printed in the score and how they should be grouped on the staves.
# Voices that are enclosed by parentheses () will go on one staff. Together they form a voice group. A voice that is not enclosed by parentheses forms a voice group on its own that will be printed on a separate staff.
# If voice groups are enclosed by curly braces {}, the corresponding staves will be connected by a big curly brace printed in front of the staves. Together they form a voice block. This format is used especially for typesetting keyboard music.
# If voice groups or braced voice blocks are enclosed by brackets [], the corresponding staves will be connected by a big bracket printed in front of the staves. Together they form a voice block.
# If voice blocks or voice groups are separated from each other by a | character, continued bar lines will be drawn between the associated staves.
# Example:
# %%score Solo  [(S A) (T B)]  {RH | (LH1 LH2)}
# If a single voice surrounded by two voice groups is preceded by a star (*), the voice is marked to be floating. This means that the voice won't be printed on it's own staff; rather the software should automatically determine, for each note of the voice, whether it should be printed on the preceding staff or on the following staff.
# Software that does not support floating voices may simply print the voice on the preceding staff, as if it were part of the preceding voice group.
# Examples:
# %%score {RH *M| LH}
# %%score {(RH1 RH2) *M| (LH1 LH2)}
# String parts in an orchestral work are usually bracketed together and the top two (1st/2nd violins) then braced outside the bracket:
# %%score [{Vln1 | Vln2} | Vla | Vc | DB]
# Any voices appearing in the tune body will only be printed if it is mentioned in the score directive.
# When the score directive occurs within the tune body, it resets the music generator, so that voices may appear and disappear for some period of time.
# If no score directive is used, all voices that appear in the tune body are printed on separate staves.
# See Canzonetta.abc for an extensive example.
# An alternative directive to %%score is %%staves.
# Both %%score and %%staves directives accept the same parameters, but measure bar indications work the opposite way. Therefore, %%staves [S|A|T|B] is equivalent to %%score [S A T B] and means that continued bar lines are not drawn between the associated staves, while %%staves [S A T B] is equivalent to %%score [S|A|T|B] and means that they are drawn.

describe "a score directive" do
  it "specifies which voices should be printed" do
    p = parse_fragment "%%score V1 V3\n[V:V1]abc[V:V2]def[V:V3]gfe"
    p.staves.count.should == 2
    p.staves[0].voices.should == ['V1']
    p.staves[1].voices.should == ['V3']
  end
  it "puts two voices on one staff with ()" do
    p = parse_fragment "%%score (V1 V2) V3\n[V:V1]abc[V:V2]def[V:V3]gfe"
    p.staves.count.should == 2
    p.staves[0].voices.should == ['V1', 'V2']
    p.staves[1].voices.should == ['V3']
  end
  it "can connect staves with curly braces {}" do
    p = parse_fragment "%%score {RH LH}"
    p.staves.count.should == 2
    p.staves[0].start_brace.should == 1
    p.staves[0].end_brace.should == 0
    p.staves[1].start_brace.should == 0
    p.staves[1].end_brace.should == 1
  end
  it "can nest () inside {}" do
    p = parse_fragment "%%score {RH (LH1 LH2)}"
    p.staves.count.should == 2
    p.staves[0].voices.count.should == 1
    p.staves[1].voices.count.should == 2
    p.staves[0].start_brace.should == 1
    p.staves[0].end_brace.should == 0
    p.staves[1].start_brace.should == 0
    p.staves[1].end_brace.should == 1
  end
  it "can connect staves with brackets []" do
    p = parse_fragment "%%score [S B]"
    p.staves.count.should == 2
    p.staves[0].start_bracket.should == 1
    p.staves[0].end_bracket.should == 0
    p.staves[1].start_bracket.should == 0
    p.staves[1].end_bracket.should == 1
  end
  it "can nest curly braces inside brackets" do
    p = parse_fragment "%%score [Solo {RH LH}]"
    p.staves.count.should == 3
    p.staves[0].start_bracket.should == 1
    p.staves[0].end_bracket.should == 0
    p.staves[1].start_bracket.should == 0
    p.staves[1].end_bracket.should == 0
    p.staves[2].start_bracket.should == 0
    p.staves[2].end_bracket.should == 1
    p.staves[1].start_brace.should == 1
    p.staves[2].end_brace.should == 1
  end
  it "specifies continued bar lines with |" do
    p = parse_fragment "%%score {RH LH}"
    p.staves[0].continue_bar_lines?.should == false
    p = parse_fragment "%%score {RH | LH}"
    p.staves[0].continue_bar_lines?.should == true
  end
  it "does not require spaces around |" do
    p = parse_fragment "%%score RH|LH"
    p.staves.count.should == 2
    p.staves[0].voices.should == ["RH"]
    p.staves[0].continue_bar_lines?.should == true
    p.staves[1].voices.should == ["LH"]
  end
  it "can specify floating voices" do
    p = parse_fragment "%%score {RH | LH}"
    p.staves[0].floaters.should == []
    p = parse_fragment "%%score {RH *M| LH}"
    p.staves[0].floaters.count.should == 1
    p.staves[0].floaters.should == ["M"]
  end
  it "can appear in the tune body as %%score" do
    p = parse_fragment "%%score S A\n[V:S]abc[V:A]abc\n%%score T B\n[V:T]def[V:B]def"
    p.staves.map { |s| s.voices }.flatten.join(' ').should == "S A"
    f = p.all_elements[9]
    f.is_a?(InstructionField).should == true
    f.value.is_a?(Array).should == true
    f.value.count.should == 2
    f.value.each { |s| s.is_a?(Staff).should == true }
    f.value.map { |s| s.voices }.flatten.join(' ').should == "T B"
  end
  it "can appear in the tune body as %%staves" do
    p = parse_fragment "%%score S A\n[V:S]abc[V:A]abc\n%%staves T B\n[V:T]def[V:B]def"
    p.staves.map { |s| s.voices }.flatten.join(' ').should == "S A"
    f = p.all_elements[9]
    f.is_a?(InstructionField).should == true
    f.value.is_a?(Array).should == true
    f.value.count.should == 2
    f.value.each { |s| s.is_a?(Staff).should == true }
    f.value.map { |s| s.voices }.flatten.join(' ').should == "T B"
  end
  it "can appear in the tune body as I:score" do
    p = parse_fragment "%%score S A\n[V:S]abc[V:A]abc\nI:score T B\n[V:T]def[V:B]def"
    p.staves.map { |s| s.voices }.flatten.join(' ').should == "S A"
    f = p.all_elements[9]
    f.is_a?(InstructionField).should == true
    f.value.is_a?(Array).should == true
    f.value.count.should == 2
    f.value.each { |s| s.is_a?(Staff).should == true }
    f.value.map { |s| s.voices }.flatten.join(' ').should == "T B"
  end
  it "can appear in the tune body as I:staves" do
    p = parse_fragment "%%score S A\n[V:S]abc[V:A]abc\nI:staves T B\n[V:T]def[V:B]def"
    p.staves.map { |s| s.voices }.flatten.join(' ').should == "S A"
    f = p.all_elements[9]
    f.is_a?(InstructionField).should == true
    f.value.is_a?(Array).should == true
    f.value.count.should == 2
    f.value.each { |s| s.is_a?(Staff).should == true }
    f.value.map { |s| s.voices }.flatten.join(' ').should == "T B"
  end
  it "can appear in an inline field as I:score" do
    p = parse_fragment "%%score S A\n[V:S]abc[V:A]abc\n[I:score T B]\n[V:T]def[V:B]def"
    p.staves.map { |s| s.voices }.flatten.join(' ').should == "S A"
    f = p.all_elements[9]
    f.is_a?(InstructionField).should == true
    f.value.is_a?(Array).should == true
    f.value.count.should == 2
    f.value.each { |s| s.is_a?(Staff).should == true }
    f.value.map { |s| s.voices }.flatten.join(' ').should == "T B"
  end
  it "can appear in an inline field as I:staves" do
    p = parse_fragment "%%score S A\n[V:S]abc[V:A]abc\n[I:staves T B]\n[V:T]def[V:B]def"
    p.staves.map { |s| s.voices }.flatten.join(' ').should == "S A"
    f = p.all_elements[9]
    f.is_a?(InstructionField).should == true
    f.value.is_a?(Array).should == true
    f.value.count.should == 2
    f.value.each { |s| s.is_a?(Staff).should == true }
    f.value.map { |s| s.voices }.flatten.join(' ').should == "T B"
  end
  it "can be omitted, in which case each voice has its own staff" do
    p = parse_fragment "[V:V1]abc[V:V2]abc[V:V3]ABC"
    p.staves.count.should == 3
    p.staves[0].voices.should == ["V1"]
    p.staves[1].voices.should == ["V2"]
    p.staves[2].voices.should == ["V3"]      
  end
  it "uses reverse bar line notation when the directive is 'staves'" do
    p = parse_fragment "%%staves S A | T B"
    p.staves[0].continue_bar_lines?.should == true
    p.staves[1].continue_bar_lines?.should == false
    p.staves[2].continue_bar_lines?.should == true
  end
end


# 11.2 Instrumentation directives
# VOLATILE: See the section 11 disclaimer.
# %%MIDI voice [<ID>] [instrument=<integer> [bank=<integer>]] [mute]
# Assigns a MIDI instrument to the indicated abc voice. The MIDI instruments are organized in banks of 128 instruments each. Both the instruments and the banks are numbered starting from one.
# The General MIDI (GM) standard defines a portable, numbered set of 128 instruments (numbered from 1-128) - see http://www.midi.org/techspecs/gm1sound.php. The GM instruments can be used by selecting bank one. Since the contents of the other MIDI banks is platform dependent, it is highly recommended to only use the first MIDI bank in tunes that are to be distributed.
# The default bank number is 1 (one).
# Example: The following assigns GM instrument 59 (tuba) to voice 'Tb'.
# %%MIDI voice Tb instrument=59
# If the voice ID is omitted, the instrument is assigned to the current voice.
# Example:
# M:C
# L:1/8
# Q:1/4=66
# K:C
# V:Rueckpos
# %%MIDI voice instrument=53 bank=2
# A3B    c2c2    |d2e2    de/f/P^c3/d/|d8    |z8           |
# V:Organo
# %%MIDI voice instrument=73 bank=2
# z2E2-  E2AG    |F2E2    F2E2        |F6  F2|E2CD   E3F/G/|
# You can use the keyword mute to mute the specified voice.
# Some abc players can automatically generate an accompaniment based on the chord symbols specified in the melody line. To suggest a GM instrument for playing this accompaniment, use the following directive:
# %%MIDI chordprog 20 % Church organ

describe "an instrumentation (%%MIDI) directive" do
  it "can specify which instrument to use for a voice" do
    p = parse_fragment "%%MIDI voice Tb instrument=59 bank=2 mute"
    p.midi.voices['Tb'].instrument.should == 59
    p.midi.voices['Tb'].bank.should == 2
    p.midi.voices['Tb'].mute?.should == true
  end
  it "defaults to not mute" do
    p = parse_fragment "%%MIDI voice Tb instrument=59 bank=2"
    p.midi.voices['Tb'].instrument.should == 59
    p.midi.voices['Tb'].bank.should == 2
    p.midi.voices['Tb'].mute?.should == false
  end
  it "defaults to bank 1" do
    p = parse_fragment "%%MIDI voice Tb instrument=59"
    p.midi.voices['Tb'].instrument.should == 59
    p.midi.voices['Tb'].bank.should == 1
    p.midi.voices['Tb'].mute?.should == false
  end
  it "can specify a voice instrument in the tune body" do
    p = parse_fragment "K:C\nV:Rueckpos\n%%MIDI voice Rueckpos instrument=53 bank=2\nA3B"
    p.items[1].is_a?(InstructionField).should == true
    p.items[1].directive.should == 'MIDI'
    p.items[1].subdirective.should == 'voice'
    midi = p.items[1].value
    midi.is_a?(MidiVoice).should == true
    midi.voice.should == "Rueckpos"
    midi.instrument.should == 53
    midi.bank.should == 2
    midi.mute?.should == false
  end
  it "defaults to current voice if voice id omitted" do
    p = parse_fragment "K:C\nV:Rueckpos\n%%MIDI voice instrument=53 bank=2\nA3B"
    p.items[1].value.voice.should == "Rueckpos"
  end
  it "can appear without an instrument specifier, to mute or unmute the current voice" do
    p = parse_fragment "K:C\nV:Rueckpos\n%%MIDI voice mute\nabc[I:MIDI voice]\n"
    p.items[1].value.voice.should == "Rueckpos"
    p.items[1].value.mute?.should == true
    p.items[5].value.voice.should == "Rueckpos"
    p.items[5].value.mute?.should == false
  end
  it "can specify an instrument to play the chord progression" do
    p = parse_fragment "%%MIDI chordprog 20"
    p.midi.chordprog.should == 20
  end
  it "can specify a chord progression instrument in the tune body" do
    p = parse_fragment "K:C\n%%MIDI chordprog 20\nabc"
    p.items[0].is_a?(InstructionField).should == true
    p.items[0].directive.should == 'MIDI'
    p.items[0].subdirective.should == 'chordprog'
    p.items[0].value.should == 20
  end
end


# 11.3 Accidental directives
# VOLATILE: This section is under active discussion. See also the section 11 disclaimer.
# %%propagate-accidentals not | octave | pitch
# When set to not, accidentals apply only to the note they're attached to. When set to octave, accidentals also apply to all the notes of the same pitch in the same octave up to the end of the bar. When set to pitch, accidentals also apply to all the notes of the same pitch in all octaves up to the end of the bar.
# The default value is pitch.
# %%writeout-accidentals none | added | all
# When set to none, modifying or explicit accidentals that appear in the key signature field (K:) are printed in the key signature. When set to added, only the accidentals belonging to the mode indicated in the K: field, are printed in the key signature. Modifying or explicit accidentals are printed in front of the notes to which they apply. When set to all, both the accidentals belonging to the mode and possible modifying or explicit accidentals are printed in front of the notes to which they apply; no key signature will be printed.
# The default value is none.

describe "the propagate-accidentals directive" do
  it "can specify no propagation at all" do
    p = parse_fragment "%%propagate-accidentals not\n_CCc|Cc"
    p.notes[0].pitch.height.should == -1
    p.notes[1].pitch.height.should == 0
    p.notes[2].pitch.height.should == 12
    p.notes[3].pitch.height.should == 0      
    p.notes[4].pitch.height.should == 12
  end
  it "can specify propagation within octave only" do
    p = parse_fragment "%%propagate-accidentals octave\n_CCc|Cc"
    p.notes[0].pitch.height.should == -1
    p.notes[1].pitch.height.should == -1
    p.notes[2].pitch.height.should == 12
    p.notes[3].pitch.height.should == 0      
    p.notes[4].pitch.height.should == 12
  end
  it "can specify propagation for all pitches" do
    p = parse_fragment "%%propagate-accidentals pitch\n_CCc|Cc"
    p.notes[0].pitch.height.should == -1
    p.notes[1].pitch.height.should == -1
    p.notes[2].pitch.height.should == 11
    p.notes[3].pitch.height.should == 0
    p.notes[4].pitch.height.should == 12
  end
  # TODO warning if any other value provided
  # TODO either support or disallow this within the tune body
end


# 11.4 Formatting directives
# VOLATILE: See the section 11 disclaimer.
# Typesetting programs should accept the set of directives in the next sections. The parameter of a directive can be a text string, a logical value true or false, an integer number, a number with decimals (just 'number' in the following), or a unit of length. Units can be expressed in cm, in, and pt (points, 1/72 inch).
# The following directives should be self-explanatory.
# 11.4.1 Page format directives
# VOLATILE: See the section 11 disclaimer.
# %%pageheight       <length>
# %%pagewidth        <length>
# %%topmargin        <length>
# %%botmargin        <length>
# %%leftmargin       <length>
# %%rightmargin      <length>
# %%indent           <length>
# %%landscape        <logical>

describe "a formatting directive" do
  it "can specify page height in points" do
    p = parse_fragment "%%pageheight 792pt"
    p.instructions['pageheight'].measure.should == 792
    p.instructions['pageheight'].unit.should == 'pt'
  end
  it "can specify page width in inches" do
    p = parse_fragment "%%pagewidth 8.5 in"
    p.instructions['pagewidth'].measure.should == 8.5
    p.instructions['pagewidth'].unit.should == 'in'
  end
  it "can specify all four margins in various units" do
    p = parse_fragment "%%topmargin 18pt"
    p.instructions['topmargin'].measure.should == 18
    p.instructions['topmargin'].unit.should == 'pt'
    p = parse_fragment "%%leftmargin 2. cm"
    p.instructions['leftmargin'].measure.should == 2
    p.instructions['leftmargin'].unit.should == 'cm'
    p = parse_fragment "%%rightmargin .6 in"
    p.instructions['rightmargin'].measure.should == 0.6
    p.instructions['rightmargin'].unit.should == 'in'
    p = parse_fragment "%%botmargin 0.8 in"
    p.instructions['botmargin'].measure.should == 0.8
    p.instructions['botmargin'].unit.should == 'in'
  end
  it "can specify indent" do
    p = parse_fragment "%%indent 0.5in"
    p.instructions['indent'].measure.should == 0.5
    p.instructions['indent'].unit.should == 'in'
  end
  it "can specify landscape or portrait" do
    p = parse_fragment "%%landscape true"
    p.instructions['landscape'].should == true
    p = parse_fragment "%%landscape false"
    p.instructions['landscape'].should == false
  end
end


  # 11.4.2 Font directives
  # VOLATILE: Font directives are due to be considered in abc 2.3 - see the section 11 disclaimer.
  # PostScript and PDF are the standard file formats for distributing printable material. For portability reasons, typesetters will use the PostScript font names. The size parameter should be an integer, but is optional.

  # %%titlefont        <font name>  <size>
  # %%subtitlefont     <font name>  <size>
  # %%composerfont     <font name>  <size>
  # %%partsfont        <font name>  <size>
  # %%tempofont        <font name>  <size>
  # %%gchordfont       <font name>  <size> % for chords symbols
  # %%annotationfont   <font name>  <size> % for "^..." annotations
  # %%infofont         <font name>  <size>
  # %%textfont         <font name>  <size>
  # %%vocalfont        <font name>  <size> % for w:
  # %%wordsfont        <font name>  <size> % for W:
  # The specifiers $1, $2, $3 and $4 can be used to change the font within a text string. The font to be used can be specified with the %%setfont-n directives. $0 resets the font to its default value. $$ gives an actual dollar sign.

  # %%setfont-1        <font name>  <size>
  # %%setfont-2        <font name>  <size>
  # %%setfont-3        <font name>  <size>
  # %%setfont-4        <font name>  <size>

describe "a font directive" do  
  it "can specify a font for various elements" do
    %w{title subtitle composer parts tempo gchord annotation info text vocal words}.each do |name|
      p = parse_fragment("%%#{name}font Bodoni 5")
      p.instructions["#{name}font"].name.should == "Bodoni"
      p.instructions["#{name}font"].size.should == 5      
    end
  end
  it "can appear without a size parameter" do
    p = parse_fragment "%%titlefont Garamond" do
      p.instructions["titlefont"].name.should == "Garamond"
      p.instructions["titlefont"].size.should == nil
    end
  end
  it 'can specify fonts for $1 $2 $3 $4' do
    (1..4).each do |i|
      p = parse_fragment "%%setfont-#{i} GillSans 12"
      p.instructions["setfont-#{i}"].name.should == "GillSans"
      p.instructions["setfont-#{i}"].size.should == 12
    end
    #TODO work out how these are applied to text strings
  end
end


# 11.4.3 Space directives
# VOLATILE: See the section 11 disclaimer.
# %%topspace         <length>
# %%titlespace       <length>
# %%subtitlespace    <length>
# %%composerspace    <length>
# %%musicspace       <length> % between composer and 1st staff
# %%partsspace       <length>
# %%vocalspace       <length>
# %%wordsspace       <length>
# %%textspace        <length>
# %%infospace        <length>
# %%staffsep         <length> % between systems
# %%sysstaffsep      <length> % between staves in the same system
# %%barsperstaff     <integer>
# %%parskipfac       <number> % space between parts
# %%lineskipfac      <number> % space between lines of text
# %%stretchstaff     <logical>
# %%stretchlast      <logical>
# %%maxshrink        <number> % shrinking notes
# %%scale            <number>

describe "a space directive" do
  it "can specify space measurements in various units" do
    %w{top title subtitle composer music parts vocal words text info}.each do |name|
      p = parse_fragment "%%#{name}space 1.5in"
      p.instructions["#{name}space"].measure.should == 1.5
      p.instructions["#{name}space"].unit.should == 'in'
    end
  end
  it "can specify staff sep measurements" do
    %w{staff syststaff}.each do |name|
      p = parse_fragment "%%#{name}sep 3 cm"
      p.instructions["#{name}sep"].measure.should == 3
      p.instructions["#{name}sep"].unit.should == 'cm'
    end
  end
  it "can specify bars per staff as an integer" do
    p = parse_fragment "%%barsperstaff 5"
    p.instructions["barsperstaff"].should == 5
    fail_to_parse_fragment "%%barsperstaff 5.1"
  end
  it "can specify skip factors as floats" do
    p = parse_fragment "%%parskipfac .5"
    p.instructions["parskipfac"].should == 0.5
    p = parse_fragment "%%lineskipfac 0.5"
    p.instructions["lineskipfac"].should == 0.5
  end
  it "can set the stretchstaff and stretchlast flags" do
    p = parse_fragment "%%stretchstaff true"
    p.instructions["stretchstaff"].should == true
    p = parse_fragment "%%stretchstaff false"
    p.instructions["stretchstaff"].should == false
    p = parse_fragment "%%stretchlast true"
    p.instructions["stretchlast"].should == true
    p = parse_fragment "%%stretchlast false"
    p.instructions["stretchlast"].should == false
  end
  it "can specify maxshrink and scale as floats" do
    p = parse_fragment "%%maxshrink .8"
    p.instructions["maxshrink"].should == 0.8
    p = parse_fragment "%%scale 0.75"
    p.instructions["scale"].should == 0.75
  end
end


# 11.4.4 Measure directives
# VOLATILE: See the section 11 disclaimer.
# %%measurefirst     <integer> % number of first measure
# %%barnumbers       <integer> % bar numbers every 'n' measures
# %%measurenb        <integer> % same as %%barnumbers
# %%measurebox       <logical>
# %%setbarnb         <integer> % set measure number

describe "a measure directive" do
  it "can specify the number of the first measure" do
    p = parse_fragment "%%measurefirst 5\n|abc|def"
    p.instructions['measurefirst'].should == 5
    p.bars[0].number.should == 5
    # p.bar(5).should = p.bars[0]
  end
  it "can specify how frequently bar numbers appear" do
    p = parse_fragment "%%barnumbers 3"
    p.instructions['barnumbers'].should == 3
    p = parse_fragment "%%measurenb 3"
    p.instructions['measurenb'].should == 3
  end
  it "can set the number of the current bar" do
    p = parse_fragment "abc|\n%%setbarnb 5\ndef"
    p.measures[0].number.should == 1
    p.measures[1].number.should == 5
    p.bar(1).should == p.bars[0]
    p.bar(2).should == nil
    p.bar(5).should == p.bars[1]
  end
  it "can set the number using an inline field" do
    p = parse_fragment "abc|[I:setbarnb 5]def"
    p.bars[0].number.should == 1
    p.bars[1].number.should == 5
    p.measure(1).should == p.bars[0]
    p.measure(2).should == nil
    p.measure(5).should == p.bars[1]
  end
end


# 11.4.5 Text directives
# VOLATILE: Text directives are due to be considered in abc 2.3 - see the section 11 disclaimer.
# The following directives can be used for inserting typeset text within an abc file.
# %%text             <text string>
# %%center           <text string>
# %%begintext
# %%...              <text string>
# %%endtext
# Notes:
# %%text prints the following text, treated as a text string.
# %%center prints the following text, treated as a text string and centred.
# %%begintext and %%endtext mark a section of lines, each of which start with %%, followed by some text. It is an alternative to several %%text lines. [Important note: some extensions offered by abc software programs relax the rule that each line between %%begintext and %%endtext must start with %%. Whilst this should not cause problems for typeset text between tunes, typeset text within a tune header or tune body should respect this rule and, in particular, must not introduce blank lines.]
# See further information about directives for more details and to find out about additional parameters for these directives.
# Recommendation for users: If you are using text directives for tune-specific information, consider instead using one of the background information fields together with a %%writefields directive (see information directives) so that the information can correctly identified by databasing software.

describe "a text directive" do
  it "can appear in the tune body" do
    p = parse_fragment "abc\n%%text Four score and 7 years ago\ndef"
    p.elements[4].class.should == TypesetText
    p.elements[4].lines.count.should == 1
    p.elements[4].lines[0].text.should == "Four score and 7 years ago"
  end
  it "can appear in the tune header" do
    p = parse_fragment "M:C\n%%text Four score and 7 years ago\nK:C\nabc"
    p.header.fields[1].type.should == :typeset_text
    p.header.fields[1].lines.count.should == 1
    p.header.fields[1].lines[0].text.should == 'Four score and 7 years ago'
  end
  it "can appear in the file header" do
    p = parse "H:history\n%%text Four score and 7 years ago\nC:Abe Lincoln\n\nX:1\nT:T\nK:C\nabc"
    p.header.fields[1].type.should == :typeset_text
    p.header.fields[1].lines.count.should == 1
    p.header.fields[1].lines[0].text.should == 'Four score and 7 years ago'
  end
  it "can appear in its own section" do
    p = parse "H:history\n\n%%text Four score and 7 years ago\n\nX:1\nT:T\nK:C\nabc"
    p.sections.count.should == 2
    p.sections[0].class.should == TypesetText
    p.sections[0].lines.count.should == 1
    p.sections[0].lines[0].text.should == 'Four score and 7 years ago'
  end
  it "is recognized as a typeset text section when there is no file header" do
    p = parse "%%text Four score and 7 years ago\n\nX:1\nT:T\nK:C\nabc"
    p.sections.count.should == 2
    p.sections[0].class.should == TypesetText
    p.sections[0].lines.count.should == 1
    p.sections[0].lines[0].text.should == 'Four score and 7 years ago'
  end
  it "is combined with adjacent ones" do
    p = parse "%%text Four score\n%%text and 7 years\n%%text ago\n\nX:1\nT:T\nK:C\n"
    p.sections.count.should == 2
    p.sections[0].lines.count.should == 3
    p.sections[0].lines[0].text.should == 'Four score'
    p.sections[0].lines[1].text.should == 'and 7 years'
    p.sections[0].lines[2].text.should == 'ago'
  end
  it "is combined with adjacent ones" do
    p = parse "%%text Four score\n%%text and 7 years\n%%text ago\n\nX:1\nT:T\nK:C\n"
    p.sections.count.should == 2
    p.sections[0].lines.count.should == 3
    p.sections[0].lines[0].text.should == 'Four score'
    p.sections[0].lines[1].text.should == 'and 7 years'
    p.sections[0].lines[2].text.should == 'ago'
  end
  it "can center a line of text" do
    p = parse "%%text Four score and 7 years ago\n\nX:1\nT:T\nK:C\n"
    p.sections[0].lines[0].text.should == 'Four score and 7 years ago'
    p.sections[0].lines[0].alignment.should == :left
    p = parse "%%center Four score and 7 years ago\n\nX:1\nT:T\nK:C\n"
    p.sections[0].lines[0].text.should == 'Four score and 7 years ago'
    p.sections[0].lines[0].alignment.should == :center
  end
  it "can combine centered with normal text" do
    p = parse "%%center Four score\n%%text and 7 years ago\n\nX:1\nT:T\nK:C\n"
    p.sections[0].lines[0].text.should == 'Four score'
    p.sections[0].lines[0].alignment.should == :center
    p.sections[0].lines[1].text.should == 'and 7 years ago'
    p.sections[0].lines[1].alignment.should == :left
  end
  it "can set several lines between %%begintext and %%endtext" do
    p = parse "%%begintext\n%%Four score\n%%and 7 years\n%%ago\n%%endtext\n\nX:1\nT:T\nK:C"
    p.sections.count.should == 2
    p.sections[0].lines.count.should == 3
    p.sections[0].lines[0].text.should == 'Four score'
    p.sections[0].lines[1].text.should == 'and 7 years'
    p.sections[0].lines[2].text.should == 'ago'
  end
  it "can combine multiline with single line text" do
    p = parse "%%begintext\n%%Four score\n%%and 7 years\n%%endtext\n%%text ago\n\nX:1\nT:T\nK:C"
    p.sections.count.should == 2
    p.sections[0].lines.count.should == 3
    p.sections[0].lines[0].text.should == 'Four score'
    p.sections[0].lines[1].text.should == 'and 7 years'
    p.sections[0].lines[2].text.should == 'ago'
  end
end


# 11.4.6 Information directives
# VOLATILE: The %%writefields directive and its formatting options are likely to be enhanced when markup is considered in abc 2.3. See also the section 11 disclaimer.
# %%writefields <list of field identifiers> [<logical>]
# The %%writefields directive allows users to choose which string-type information fields appear in the printed score (see the information fields table for a list of string-type fields). It is followed by a list of field identifiers and, optionally, the logical value true or false. If the logical value is missing it is taken as true.
# The %%writefields directive also applies to certain instruction fields - namely X:reference number, P:parts and Q:tempo.
# The default is "%%writefields TCOPQwW" meaning that the title (T), composer (C), origin (O), parts (P), tempo (Q), aligned words (w) and other words (W) are printed out by default (see typesetting information fields for how these should be typeset). Each subseqent %%writefields directive combines with this list, rather than overriding it.
# Examples:
# %%writefields O false         % the O field is not printed out - other defaults remain
# %%writefields X               % the X: field is printed out
# %%writefields BCDFGHNORSTWwXZ % all string-type fields are printed out
# Typesetting software conforming to abc 2.1 may format the information strings in any way it chooses.
# Comment: The %%writefields directive can be used in place of a number of directives introduced in abc 2.0:
# "%%writefields X" can be used as an alternative to "%%withxrefs"
# "%%writefields Ww false" can be used as an alternative to"%%musiconly"
# "%%writefields" is a partial alternative to "%%writehistory" and "%%infoname"
# See further information about directives for more details of the 2.0 alternatives.


# 11.4.7 Separation directives
# VOLATILE: See the section 11 disclaimer.
# %%sep     % draw a horizontal separator, i.e. a line
# %%vskip   % insert some vertical space
# %%newpage % start a new page
# See further information about directives for more details and to find out about additional parameters for these directives.


# 11.4.8 Miscellaneous directives
# VOLATILE: See the section 11 disclaimer.
# %%exprabove        <logical>
# %%exprbelow        <logical>
# %%graceslurs       <logical> % grace notes slur to main note
# %%infoline         <logical> % rhythm and origin on the same line
# %%oneperpage       <logical>
# %%vocalabove       <logical>
# %%freegchord       <logical> % print '#', 'b' and '=' as they are
# %%printtempo       <logical>
# The default value for these directives is false.

describe 'any directive listed as "miscellaneous directives"' do
  it "will have a boolean value" do
    d = %w{exprabove exprbelow graceslurs infoline oneperpage vocalabove freegchord printtempo}
    d.each do |name|
      p = parse_fragment "%%#{name} true"
      p.instructions[name].should == true
      p = parse_fragment "%%#{name} false"
      p.instructions[name].should == false
    end
  end
end


# 11.5 Application specific directives
# Applications may introduce their own directives. These directives should start with the name of the application, followed a colon, folowed by the name of the directive.
# Example:
# %%noteedit:fontcolor blue

describe "pseudo-comment support" do
  it "accepts arbitrary app-specific directives" do
    p = parse_fragment "%%any_app:any_directive value"
    p.instructions['any_app:any_directive'].should == 'value'
  end
end


# 11.6 Further information about directives
# Since stylesheet directives are not formally part of the abc standard, only a subset is included here. For additional directives and further information about those listed here, see the user manuals for programs that implement them, in particular:
# the format.txt file included with abcm2ps
# the abcguide.txt file included with abcMIDI
# the abctab2ps User's guide
# Back to top



