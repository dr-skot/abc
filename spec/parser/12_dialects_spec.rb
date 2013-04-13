# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('.')
require 'spec/parser/spec_helper'


# 12. Dialects, strict / loose interpretation and backwards compatibility
# Unfortunately a number of dialects of abc have arisen over the years, partly due to differences in implementation, together with unfinished drafts of the abc standard and ambiguities within it.
# Version 2.1 of the standard aims to address this fragmentation of abc notation with a robust, but tolerant approach that should accommodate as many users as possible for several years to come and, as far as possible, restore backwards compatibility.
# There are three main approaches:
# - the introduction of new I: directives to allow for preferences in dialects;
# - the concepts of strict and loose interpretation of the standard (together with recommendations to software developers for dealing with loose interpretations);
# - statistically-based decisions about default settings.
# The aim is that, even under strict interpretation, most current dialects are still available via the new I: directives.
# Comment: Dialects not available under strict interpretation are those where one symbol is used for two different purposes - for example, a ! symbol used to denote both line-breaks and decorations; fortunately, of the 160,000 tunes currently available in the abcnotation.com tune search only around 60 (0.04%) employ this usage.


# 12.1 Dialect differences
# The main differences that have arisen are line-breaks, decoration delimiters and chord delimiters.


# 12.1.1 Line-breaking dialects
# By default, a (forced) score line-break is typeset by using a code line-break - see typesetting line-breaks.
# In the past the ! symbol has instead been used to indicate score line-breaks - this symbol is now used to denote decorations.
# Comment: The ! symbol was introduced by abc2win, a very popular program in its time, although now moribund. Of the 160,000 tunes currently available in the abcnotation.com tune search, only around 1,600 (10%) use the ! symbol to denote line-breaks.
# Although the use of the ! symbol for line-breaking is now deprecated (see outdated line-breaking), users who wish to continue using the ! symbol for line-breaking merely need to include the "I:linebreak !" directive, either in the file header or individually tune by tune - see typesetting line-breaks.
# Example: The following abc code would result in two lines of music.
# I:linebreak !
# K:G
# ABC DEF|!FED ABC|]
# Finally a new line-breaking symbol, $, has been introduced as an alternative to using code line-breaks.
# Comment: The $ symbol is effectively a replacement for !. It is aimed at those users who want ! as the decoration delimiter but who prefer to use code line-breaks without generating corresponding score line-breaks.

# ^^ covered in the spec for section 6.1.1 Typesetting line-breaks


# 12.1.2 Decoration dialects
# Decorations are delimited using the ! symbol - see decorations.
# In the past the + symbol has instead been used to denote decorations - this symbol is now deprecated for decorations.
# Comment: Decorations were first introduced in draft standard 1.7.6 (which was never formally adopted) with the ! symbol. In abc 2.0 (adopted briefly whilst discussions about abc 2.1 were taking place) this was changed to the + symbol. Neither are in widespread use, but the ! symbol is much more common - of the 160,000 tunes currently available in the abcnotation.com tune search, only around 100 (0.07%) use the + symbol to delimit decorations, whereas around 1,350 (0.85%) use the ! symbol.
# Users who wish to continue using the + symbol for decorations merely need to include the "I:decoration +" directive, either in the file header or individually tune by tune - see decorations. All +…+ decorations will then be treated as if they were the corresponding !…! decoration and any !…! decorations will generate an error message.
# Note that the "I:decoration +" directive is automatically invoked by the "I:linebreak !" directive. Also note that the !+! decoration has no + equivalent - +plus+ should be used instead.
# Recommendation for users: Given the very small uptake of the + symbol for decorations, "I:decoration +" directive is not recommended. However, it is retained for users who wish to use the ! symbol for line-breaking in legacy abc files.
# For completeness the "I:decoration !", the default setting, is also available to allow individual tunes to use !…! decorations in a file where "I:decoration +" is set in the file header.

describe 'the "I:decoration" instruction' do
  it 'can change the decoration delimiter to +' do
    p = parse_value_fragment "I:decoration +\n+trill+abc"
    p.directive_values("decoration").should == ["+"]
    p.notes[0].decorations[0].symbol.should == 'trill'
  end
  it 'can change the decoration delimiter back to !' do
    p = parse_value_fragment "I:decoration +\nI:decoration !\n!trill!abc"
    p.notes[0].decorations[0].symbol.should == 'trill'
  end
  it 'allows !+! but not +++' do
    p = parse_value_fragment "!+!abc"
    p.notes[0].decorations[0].symbol.should == '+'
    fail_to_parse_fragment "I:decoration +\n+++abc"
    p = parse_value_fragment "I:decoration +\n+plus+abc"
    p.notes[0].decorations[0].symbol.should == 'plus'
  end
  # TODO appear in fileheader
  # TODO overruled by tuneheader
  # TODO not tune body
end


# 12.1.3 Chord dialects
# Chords are delimited using [] symbols - see chords and unisons.
# In the past the + symbol has instead been used to delimit chords - this symbol is no longer in use for chords.
# Comment: In early versions of the abc standard (1.2 to 1.5), chords were delimited with + symbols. However, this made it hard to see where one chord ended and another began and the chord delimiters were changed to [] in 1.6 (November 1996). Of the 160,000 tunes currently available in the abcnotation.com tune search, only around 420 (0.25%) use the + symbol to delimit chords. Given the small uptake and the successful introduction of the [] symbols, there is no I: directive available which allows the use of + symbols and this usage is now obsolete.

# ^^ no new coverage needed


# 12.2 Loose interpretation
# Comment: There are around 160,000 tunes currently available in the abcnotation.com tune search - loose interpretation of the abc standard maintains backwards compatibility without any changes required for this huge and valuable resource.
# Any abc file without a version number, or with a version number of 2.0 or less (see abc file identification and version field), should be interpreted loosely. Developers should do their best to provide programs that understand legacy abc files, but users should be aware that loose interpretations may different from one abc program to another.
# Recommendation for users: Try to avoid loose interpretation if possible; loose interpretation means that if you pass abc notated tunes on to friends, or post them on the web, they may not appear as you hoped.
# Recommendation 1 for developers: Do your best! The most difficult tunes to deal with are those which use the same symbol for two different purposes - in particular the ! symbol for both decorations and line-breaking. Here is an algorithm for helping to deal with !decoration! syntax and ! line-breaks in the same tune:
# When encountering a !, scan forward. If you find another ! before encountering any of |[:], a space, or the end of a line, then you have a decoration, otherwise it is a line-break.
# Recommendation 2 for developers: Although moving towards strict interpretations should make life easier for everybody (developers and users alike), you should allow users to switch easily between strict and loose interpretation, perhaps via a command line switch or a GUI check-box. For example, a user who imports an old abc file may wish to see how it would be interpreted strictly, perhaps to establish how many strict errors need fixing.


# 12.3 Strict interpretation
# Any abc file with an abc version number greater than or equal to 2.1 (see abc file identification and version field) should be interpreted strictly, with errors indicated to the user as such.

