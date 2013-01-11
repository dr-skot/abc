# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('.')
require 'spec/abc_standard/spec_helper'

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
    p = parse_value "J:unknown field\n\nX:1\nT:T\nK:C"
    # TODO use a string for this instead of regex
    p.header.value('J').should == 'unknown field'
  end
  it "can have an unrecognized identifier in the tune header" do
    p = parse_value "X:1\nT:T\nJ:unknown field\nK:C"
    p.tunes[0].header.value('J').should == 'unknown field'
  end
  it "can have an unrecognized identifier in the tune body" do
    p = parse_value "X:1\nT:T\nK:C\nabc\nJ:unknown field\ndef"
    p.tunes[0].items[3].is_a?(Field).should == true
    p.tunes[0].items[3].value.should == 'unknown field'
  end
  it "can have an unrecognized identifier inline in the tune" do
    p = parse_value "X:1\nT:T\nK:C\nabc[J:unknown field]def"
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
    p = parse_value "C:John Lennon\nC:Paul McCartney\n\nX:1\nT:\nK:C"
    p.composer.should == ["John Lennon", "Paul McCartney"]
  end
  it "overrides previous value for meter fields" do
    p = parse_value "M:C\nM:3/4\n\nX:1\nT:\nK:C"
    p.meter.measure_length.should == Rational(3, 4)
  end
end


# 3.1.1 X: - reference number
# The X: (reference number) field is used to assign to each tune within a tunebook a unique reference number (a positive integer), for example: X:23.
# The X: field is also used to indicate the start of the tune (and hence the tune header), so all tunes must start with an X: field and only one X: field is allowed per tune.
# The X: field may be empty, although this is not recommended.

describe "X: (reference number) field" do
  it "cannot be repeated" do
    p = parse "X:1\nT:Title\nX:2\nK:C"
    p.errors[0].message.should == I18n.t('abc.errors.duplicate', item:"refnum (X:) field")
  end
  it "must be an integer" do
    p = parse "X:one\nT:Title\nK:C"
    p.errors[0].message.should == "refnum (X:) field must be a positive integer"
  end
  it "can be empty" do
    p = parse_value "X:\nT:Title\nK:C"
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
    p = parse_value "X:1\nT:\nK:C"
    p.tunes[0].title.should == ""
  end
  it "can be repeated" do
    p = parse_value "X:1\nT:T1\nT:T2\nK:C"
    p.tunes[0].title.should == ["T1", "T2"]
  end
  it "can be used within a tune" do
    p = parse_value "X:1\nT:T\nK:C\nT:Part1\nabc\nT:Part2\ndef"
    p.tunes[0].items[0].is_a?(Field).should == true
    p.tunes[0].items[0].value.should == "Part1"
  end
end

# 3.1.3 C: - composer
# The C: field is used to indicate the composer(s).
# See typesetting information fields for details of how the composer is included in the printed score.

describe "C: (composer) field" do
  it "is recognized" do
    p = parse_value_fragment "C:Brahms"
    p.composer.should == "Brahms"
  end
end


# 3.1.4 O: - origin
# The O: field indicates the geographical origin(s) of a tune.
# If possible, enter the data in a hierarchical way, like:
# O:Canada; Nova Scotia; Halifax.
# O:England; Yorkshire; Bradford and Bingley.
# Recommendation: It is recommended to always use a ";" (semi-colon) as the separator, so that software may parse_value the field. However, abc 2.0 recommended the use of a comma, so legacy files may not be parse_value-able under abc 2.1.
# This field may be especially useful for traditional tunes with no known composer.
# See typesetting information fields for details of how the origin information is included in the printed score.

describe "O: (origin) field" do
  it "is recognized" do
    p = parse_value_fragment "O:Canada; Nova Scotia; Halifax.\nO:England; Yorkshire; Bradford and Bingley."
    p.origin.should == ["Canada; Nova Scotia; Halifax.", "England; Yorkshire; Bradford and Bingley."]
  end
end


# 3.1.5 A: - area
# Historically, the A: field has been used to contain area information (more specific details of the tune origin). However this field is now deprecated and it is recommended that such information be included in the O: field.

describe "A: (area) field" do
  it "is recognized" do
    p = parse_value_fragment "O:Nova Scotia\nA:Halifax"
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
    p = parse_value_fragment "M:6/8\nabc"
    p.meter.numerator.should == 6
    p.meter.denominator.should == 8
  end
  it "can be \"C\", meaning common time" do
    p = parse_value_fragment "M:C\nabc"
    p.meter.numerator.should == 4
    p.meter.denominator.should == 4
    p.meter.symbol.should == :common
  end
  it "can be \"C|\", meaning cut time" do
    p = parse_value_fragment "M:C|\nabc"
    p.meter.numerator.should == 2
    p.meter.denominator.should == 4
    p.meter.symbol.should == :cut
  end
  it "can handle complex meter with parentheses" do
    p = parse_value_fragment "M:(2+3+2)/8\nabc"
    p.meter.complex_numerator.should == [2,3,2]
    p.meter.numerator.should == 7
    p.meter.denominator.should == 8
  end
  it "can handle complex meter without parentheses" do
    p = parse_value_fragment "M:2+3+2/8\nabc"
    p.meter.complex_numerator.should == [2,3,2]
    p.meter.numerator.should == 7
    p.meter.denominator.should == 8
  end
  it "defaults to free meter" do
    p = parse_value_fragment "abc"
    p.meter.symbol.should == :free
  end
  it "can be explicitly defined as none" do
    p = parse_value_fragment "M:none\nabc"
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
    p = parse_value_fragment "L:1/4"
    p.unit_note_length.should == Rational(1, 4)
  end
  it "accepts whole numbers" do
    p = parse_value_fragment "L:1\nabc"
    p.unit_note_length.should == 1
  end
  it "defaults to 1/16 if meter is less than 0.75" do
    p = parse_value_fragment "M:74/100\n"
    p.unit_note_length.should == Rational(1, 16)
  end
  it "defaults to 1/8 if meter is 0.75 or greater" do
    p = parse_value_fragment "M:3/4\n"
    p.unit_note_length.should == Rational(1, 8)
  end
  it "will not change note lengths when the meter changes in the tune" do
    p = parse_value_fragment "M:3/4\nK:C\na\nM:2/4\nb"
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
    p = parse_value_fragment "X:1\nQ:1/4=120"
    p.tempo.beat_length.should == Rational(1, 4)
    p.tempo.beat_parts.should == [Rational(1, 4)]
    p.tempo.bpm.should == 120
  end
  it "can divide the beat into parts" do
    p = parse_value_fragment "X:1\nQ:1/4 3/8 1/4 3/8=40"
    p.tempo.beat_length.should == Rational(5, 4)
    p.tempo.beat_parts.should == 
      [Rational(1, 4), Rational(3, 8), Rational(1, 4), Rational(3, 8)]
    p.tempo.bpm.should == 40
  end
  it "can take a label before the tempo indicator" do
    p = parse_value_fragment "X:1\nQ:\"Allegro\" 1/4=120"
    p.tempo.label.should == "Allegro"
  end
  it "can take a label after the tempo indicator" do
    p = parse_value_fragment "X:1\nQ:3/8=50 \"Slowly\""
    p.tempo.label.should == "Slowly"
  end
  it "can take a label without an explicit tempo indication" do
    p = parse_value_fragment "Q:\"Andante\""
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
    p = parse_value_fragment "X:1\nP:A\nK:C\nabc"
    p.part_sequence.list.should == ['A']
  end
  it "can be two parts" do
    p = parse_value_fragment "X:1\nP:AB\nK:C\nabc"
    p.part_sequence.list.should == ['A', 'B']
  end
  it "can be one part repeating" do
    p = parse_value_fragment "X:1\nP:A3\nK:C\nabc"
    p.part_sequence.list.should == ['A', 'A', 'A']
  end
  it "can be two parts with one repeating" do
    p = parse_value_fragment "X:1\nP:A2B\nK:C\nabc"
    p.part_sequence.list.should == ['A', 'A', 'B']
  end
  it "can be two parts repeating" do
    p = parse_value_fragment "X:1\nP:(AB)3\nK:C\nabc"
    p.part_sequence.list.should == ['A', 'B', 'A', 'B', 'A', 'B']
  end
  it "can have nested repeats" do
    p = parse_value_fragment "X:1\nP:(A2B)3\nK:C\nabc"
    p.part_sequence.list.join('').should == 'AABAABAAB'
  end
  it "can contain dots anywhere" do
    p = parse_value_fragment "X:1\nP:.(.A.2.B.).3.\nK:C\nabc"
    p.part_sequence.list.join('').should == 'AABAABAAB'
  end
end

describe "parts body field" do
  it "separates parts" do
    p = parse_value_fragment "K:C\nP:A\nabc2\nP:B\ndefg"
    p.parts['A'].notes.count.should == 3
    p.parts['B'].notes.count.should == 4
  end
  it "works as an inline field" do
    p = parse_value_fragment "[P:A]abc2[P:B]defg"
    p.parts['A'].notes.count.should == 3
    p.parts['B'].notes.count.should == 4
  end
end

describe "next_parts method" do
  it "works" do
    p = parse_value_fragment "P:BA2\nK:C\n[P:A]abc2[P:B]defg"
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
    p = parse_value_fragment "Z:abc-copyright &copy; John Smith"
    p.transcription.should == "abc-copyright © John Smith"
  end
  it "can appear in the file header" do
    p = parse_value "Z:abc-copyright &copy; John Smith\n\nX:1\nT:\nK:C"
    p.transcription.should == "abc-copyright © John Smith"
  end
  it "can't appear in the tune body" do
    fail_to_parse_fragment "K:C\nZ:abc-copyright © John Smith\nabc"
  end
  # TODO specific support for abc-copyright and abc-edited-by
end


# 3.1.11 N: - notes
# Contains general annotations, such as references to other tunes which are similar, details on how the original notation of the tune was converted to abc, etc.
# See typesetting information fields for details of how notes may be included in the printed score.

describe "N: (notes) field" do
  it "can appear in the tune header" do
    p = parse_value_fragment "N:notes are called notations"
    p.notations.should == "notes are called notations"
  end
  it "can appear in the file header" do
    p = parse_value "N:notes are called notations\n\nX:1\nT:\nK:C"
    p.notations.should == "notes are called notations"
  end
  it "can appear in the tune body" do
    p = parse_value_fragment "abc\nN:notes are called notations\ndef"
    p.items[3].value.should == "notes are called notations"
  end
  it "can appear as an inline field" do
    p = parse_value_fragment "abc[N:notes are called notations]def"
    p.items[3].value.should == "notes are called notations"
  end
end


# 3.1.12 G: - group
# Database software may use this field to group together tunes (for example by instruments) for indexing purposes. It can also be used for creating medleys - however, this usage is not standardised.

describe "G: (group) field" do
  it "can appear in the tune header" do
    p = parse_value_fragment "G:group"
    p.group.should == "group"
  end
  it "can appear in the file header" do
    p = parse_value "G:group\n\nX:1\nT:\nK:C"
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
    p = parse_value_fragment "H:history"
    p.history.should == "history"
  end
  it "can appear in the file header" do
    p = parse_value "H:history\n\nX:1\nT:\nK:C"
    p.history.should == "history"
  end
  it "can't appear in the tune body" do
    fail_to_parse_fragment "abc\nH:history\ndef"
  end
  it "can't appear as an inline field" do
    fail_to_parse_fragment "abc[H:history]def"
  end
  it "differentiates between continuation and separate anecdotes" do 
    p = parse_value_fragment "H:this is considered\n+:as a single entry\nH:this usage is considered as two entries\nH:rather than one"
    p.history.should == ["this is considered as a single entry", "this usage is considered as two entries", "rather than one"]
  end
end


# 3.1.14 K: - key
# The key signature should be specified with a capital letter (A-G) which may be followed by a # or b for sharp or flat respectively. In addition the mode should be specified (when no mode is indicated, major is assumed).
# For example, K:C major, K:A minor, K:C ionian, K:A aeolian, K:G mixolydian, K:D dorian, K:E phrygian, K:F lydian and K:B locrian would all produce a staff with no sharps or flats. The spaces can be left out, capitalisation is ignored for the modes and in fact only the first three letters of each mode are parse_valued so that, for example, K:F# mixolydian is the same as K:F#Mix or even K:F#MIX. As a special case, minor may be abbreviated to m.
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
    p = parse_value_fragment "K:D"
    p.key.tonic.should == "D"
  end
  it "can have a flat in the tonic" do
    p = parse_value_fragment "K:Eb"
    p.key.tonic.should == "Eb"
  end
  it "can have a sharp in the tonic" do
    p = parse_value_fragment "K:F#"
    p.key.tonic.should == "F#"
  end
  it "defaults to major mode" do
    p = parse_value_fragment "K:D"
    p.key.mode.should == "major"
  end
  it "recognizes maj as major" do
    p = parse_value_fragment "K:D maj"
    p.key.mode.should == "major"
  end
  it "recognizes m as minor" do
    p = parse_value_fragment "K:Dm"
    p.key.mode.should == "minor"
  end
  it "recognizes min as minor" do
    p = parse_value_fragment "K:D min"
    p.key.mode.should == "minor"
  end
  it "recognizes mixolydian" do
    p = parse_value_fragment "K:D mix"
    p.key.mode.should == "mixolydian"
  end
  it "recognizes dorian" do
    p = parse_value_fragment "K:D dor"
    p.key.mode.should == "dorian"
  end
  it "recognizes locrian" do
    p = parse_value_fragment "K:D loc"
    p.key.mode.should == "locrian"
  end
  it "recognizes phrygian" do
    p = parse_value_fragment "K:D phrygian"
    p.key.mode.should == "phrygian"
  end
  it "recognizes lydian" do
    p = parse_value_fragment "K:D lydian"
    p.key.mode.should == "lydian"
  end
  it "recognizes aeolian" do
    p = parse_value_fragment "K:D loc"
    p.key.mode.should == "locrian"
  end
  it "recognizes ionian" do
    p = parse_value_fragment "K:D ion"
    p.key.mode.should == "ionian"
  end
  it "ignores all but the first 3 letters of the mode" do
    p = parse_value_fragment "K:D mixdkafjeaadkfafipqinv"
    p.key.mode.should == "mixolydian"
  end
  it "ignores capitalization of the mode" do
    p = parse_value_fragment "K:D Mix"
    p.key.mode.should == "mixolydian"
    p = parse_value_fragment "K:DMIX"
    p.key.mode.should == "mixolydian"
    p = parse_value_fragment "K:DmIX"
    p.key.mode.should == "mixolydian"
  end
  it "delivers accidentals for major key" do
    p = parse_value_fragment "K:Eb"
    sig = p.key.signature
    sig.should include 'A' => -1, 'B' => -1, 'E' => -1
    sig.should_not include 'C', 'D', 'F', 'G'
  end
  it "delivers accidentals for key with mode" do
    p = parse_value_fragment "K:A# Phr"
    sig = p.key.signature
    sig.should include 'C' => 1, 'D' => 1, 'E' => 1, 'F' => 1, 'G' => 1, 'A' => 1
    sig.should_not include 'B'
  end
  it "can take extra accidentals" do
    p = parse_value_fragment "K:Ebminor=e^c"
    p.key.extra_accidentals.should include 'E' => 0, 'C' => 1
  end
  it "delivers accidentals for key with extra accidentals" do
    p = parse_value_fragment "K:F =b ^C"
    sig = p.key.signature
    sig.should include 'C' => 1
    sig.should_not include %w{D E F G A B}
  end
  it "allows explicitly defined signatures" do
    p = parse_value_fragment "K:D exp _b _e ^f"
    p.key.tonic.should == "D"
    p.key.mode.should == nil
    p.key.signature.should == {'B' => -1, 'E' => -1, 'F' => 1}
  end
  # TODO case of the accidental determines on which line the accidental should be drawn
  it "allows K:none" do
    p = parse_value_fragment "K:none"
    p.key.tonic.should == nil
    p.key.mode.should == nil
    p.key.signature.should == {}
  end
  it "uses signature C#, F#, G natural for highland pipes" do
    p = parse_value_fragment "K:HP"
    p.key.highland_pipes?.should == true
    p.key.tonic.should == nil
    p.key.signature.should == {'C'=> 1, 'F' => 1, 'G' => 0}
    p = parse_value_fragment "K:Hp"
    p.key.highland_pipes?.should == true
    p.key.tonic.should == nil
    p.key.signature.should == {'C'=> 1, 'F' => 1, 'G' => 0}
  end
  it "will not show accidentals for K:HP" do
    p = parse_value_fragment "K:HP"
    p.key.show_accidentals?.should == false
  end
  it "will show accidentals for K:Hp" do
    p = parse_value_fragment "K:Hp"
    p.key.show_accidentals?.should == true
  end
end


# 3.1.15 R: - rhythm
# Contains an indication of the type of tune (e.g. hornpipe, double jig, single jig, 48-bar polka, etc). This gives the musician some indication of how a tune should be interpreted as well as being useful for database applications (see background information). It has also been used experimentally by playback software (in particular, abcmus) to provide more realistic playback by altering the stress on particular notes within a bar.
# See typesetting information fields for details of how the rhythm may be included in the printed score.

describe "R: (rhythm) field" do
  it "can appear in the tune header" do
    p = parse_value_fragment "R:rhythm"
    p.rhythm.should == "rhythm"
  end
  it "can appear in the file header" do
    p = parse_value "R:rhythm\n\nX:1\nT:\nK:C"
    p.rhythm.should == "rhythm"
  end
  it "can appear in the tune body" do
    p = parse_value_fragment "abc\nR:rhythm\ndef"
    p.items[3].value.should == "rhythm"
  end
  it "can appear as an inline field" do
    p = parse_value_fragment "abc[R:rhythm]def"
    p.items[3].value.should == "rhythm"
  end
end


# 3.1.16 B:, D:, F:, S: - background information
# The information fields B:book (i.e. printed tune book), D:discography (i.e. a CD or LP where the tune can be heard), F:file url (i.e. where the either the abc tune or the abc file can be found on the web) and S:source (i.e. the circumstances under which a tune was collected or learned), as well as the fields H:history, N:notes, O:origin and R:rhythm mentioned above, are used for providing structured background information about a tune. These are particularly aimed at large tune collections (common in abc since its inception) and, if used in a systematic way, mean that abc database software can sort, search and filter on specific fields (for example, to sort by rhythm or filter out all the tunes on a particular CD).
# The abc standard does not prescribe how these fields should be used, but it is typical to employ several fields of the same type each containing one piece of information, rather than one field containing several pieces of information (see English.abc for some examples).
# See typesetting information fields for details of how background information may be included in the printed score.

describe "B: (book) field" do
  it "can appear in the tune header" do
    p = parse_value_fragment "B:book"
    p.book.should == "book"
  end
  it "can appear in the file header" do
    p = parse_value "B:book\n\nX:1\nT:\nK:C"
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
    p = parse_value_fragment "D:discography"
    p.discography.should == "discography"
  end
  it "can appear in the file header" do
    p = parse_value "D:discography\n\nX:1\nT:\nK:C"
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
    p = parse_value_fragment "F:file url"
    p.url.should == "file url"
  end
  it "can appear in the file header" do
    p = parse_value "F:file url\n\nX:1\nT:\nK:C"
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
    p = parse_value_fragment "S:source"
    p.source.should == "source"
  end
  it "can appear in the file header" do
    p = parse_value "S:source\n\nX:1\nT:\nK:C"
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
    p = parse_value_fragment "I:name value"
    p.instructions['name'].should == "value"
  end
  it "can appear in the file header" do
    p = parse_value "I:name value\n\nX:1\nT:\nK:C"
    p.instructions['name'].should == "value"
  end
  it "can appear in the tune body" do
    p = parse_value_fragment "abc\nI:name value\ndef"
    p.items[3].name.should == "name"
    p.items[3].value.should == "value"
  end
  it "can appear as an inline field" do
    p = parse_value_fragment "abc[I:name value]def"
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
    p = parse_value "I:abc-charset utf-8\n\nX:1\nT:\nK:C"
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
    p = parse_value_fragment "I:abc-version 2.0"
    p.instructions['abc-version'].should == "2.0"
  end
  it "can appear in the file header" do
    p = parse_value "I:abc-version 2.0\n\nX:1\nT:\nK:C"
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
    p = parse_value_fragment "I:abc-include #{@filename}\nK:C"
    p.composer.should == 'Bach'
  end
  it "can appear in the file header" do
    p = parse_value "I:abc-include #{@filename}\n\nX:1\nT:\nK:C"
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
    p = parse_value_fragment "I:abc-include #{@filename}\nK:C"
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
    p = parse_value_fragment "H:let me tell you a little\n+:about this song"
    p.history.should == "let me tell you a little about this song"
  end
  it "combines lyric lines with '+:'" do
    p = parse_value_fragment "GCEA\nw:my dog\n+:has fleas"
    p.notes[3].lyric.text.should == "fleas"
  end
  it "combines symbol lines with '+:'" do
    p = parse_value_fragment "GCEA\ns:**\n+:*!f!"
    p.notes[3].decorations[0].symbol.should == "f"
  end
  it "combines more than two lines" do
    p = parse_value_fragment "H:let me tell\n+:you a little\n+:about \n+:this song"
    p.history.should == "let me tell you a little about this song"
  end
  it "works across end comments" do
    p = parse_value_fragment "H:let me tell you a little %comment\n+:about this song"
    p.history.should == "let me tell you a little about this song"
  end
  it "works across comment lines" do
    p = parse_value_fragment "H:let me tell you a little \n%comment\n+:about this song"
    p.history.should == "let me tell you a little about this song"
  end
  it "works across stylesheet directives" do
    p = parse_value_fragment ["abcd abc",
                        "%vocalfont Times-Roman 14",
                        "w:nor-mal",
                        "% legal, but not recommended",
                        "%vocalfont Times-Italic *",
                        "+:i-ta-lic",
                        "%%vocalfont Times-Roman 14",
                        "+:nor-mal"].join("\n")
    # TODO figure out how this gets parse_valued
    # TODO make it easier to recover lyrics
  end
end


