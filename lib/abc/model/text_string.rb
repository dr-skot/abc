# -*- coding: utf-8 -*-
require "htmlentities"

module ABC

  MNEMONICS = {
    '`A' => 'À',
    '`a' => 'à',
    '`E' => 'È',
     '`e' => 'è',
     '`I' => 'Ì',
     '`i' => 'ì',
     '`O' => 'Ò',
     '`o' => 'ò',
     '`U' => 'Ù',
     '`u' => 'ù',
     '\'A' => 'Á',
     '\'a' => 'á',
     '\'E' => 'É',
     '\'e' => 'é',
     '\'I' => 'Í',
     '\'i' => 'í',
     '\'O' => 'Ó',
     '\'o' => 'ó',
     '\'U' => 'Ú',
     '\'u' => 'ú',
     '\'Y' => 'Ý',
     '\'y' => 'ý',
     '^A' => 'Â',
     '^a' => 'â',
     '^E' => 'Ê',
     '^e' => 'ê',
     '^I' => 'Î',
     '^i' => 'î',
     '^O' => 'Ô',
     '^o' => 'ô',
     '^U' => 'Û',
     '^u' => 'û',
     '^Y' => 'Ŷ',
     '^y' => 'ŷ',
     '~A' => 'Ã',
     '~a' => 'ã',
     '~N' => 'Ñ',
     '~n' => 'ñ',
     '~O' => 'Õ',
     '~o' => 'õ',
     '"A' => 'Ä',
     '"a' => 'ä',
     '"E' => 'Ë',
     '"e' => 'ë',
     '"I' => 'Ï',
     '"i' => 'ï',
     '"O' => 'Ö',
     '"o' => 'ö',
     '"U' => 'Ü',
     '"u' => 'ü',
     '"Y' => 'Ÿ',
     '"y' => 'ÿ',
     'cC' => 'Ç',
     'cc' => 'ç',
     'AA' => 'Å',
     'aa' => 'å',
     '/O' => 'Ø',
     '/o' => 'ø',
     'uA' => 'Ă',
     'ua' => 'ă',
     'uE' => 'Ĕ',
     'ue' => 'ĕ',
     'vS' => 'Š',
     'vs' => 'š',
     'vZ' => 'Ž',
     'vz' => 'ž',
     'HO' => 'Ő',
     'Ho' => 'ő',
     'HU' => 'Ű',
     'Hu' => 'ű',
     'AE' => 'Æ',
     'ae' => 'æ',
     'OE' => 'Œ',
     'oe' => 'œ',
     'ss' => 'ß',
     'DH' => 'Ð',
     'dh' => 'ð',
     'TH' => 'Þ',
     'th' => 'þ',
  }

  # MNEMONIC_REGEXP = Regexp.new('/\\(%s)/' % MNEMONICS.keys.join('|'))
  
=begin
  ACCENTS_AND_LIGATURES = ABC::Key.split_keys(
    '\\`A &Agrave; \\u00c0' => 'À',
     '\\`a &agrave; \\u00e0' => 'à',
     '\\`E &Egrave; \\u00c8' => 'È',
     '\\`e &egrave; \\u00e8' => 'è',
     '\\`I &Igrave; \\u00cc' => 'Ì',
     '\\`i &igrave; \\u00ec' => 'ì',
     '\\`O &Ograve; \\u00d2' => 'Ò',
     '\\`o &ograve; \\u00f2' => 'ò',
     '\\`U &Ugrave; \\u00d9' => 'Ù',
     '\\`u &ugrave; \\u00f9' => 'ù',
     '\\\'A &Aacute; \\u00c1' => 'Á',
     '\\\'a &aacute; \\u00e1' => 'á',
     '\\\'E &Eacute; \\u00c9' => 'É',
     '\\\'e &eacute; \\u00e9' => 'é',
     '\\\'I &Iacute; \\u00cd' => 'Í',
     '\\\'i &iacute; \\u00ed' => 'í',
     '\\\'O &Oacute; \\u00d3' => 'Ó',
     '\\\'o &oacute; \\u00f3' => 'ó',
     '\\\'U &Uacute; \\u00da' => 'Ú',
     '\\\'u &uacute; \\u00fa' => 'ú',
     '\\\'Y &Yacute; \\u00dd' => 'Ý',
     '\\\'y &yacute; \\u00fd' => 'ý',
     '\\^A &Acirc; \\u00c2' => 'Â',
     '\\^a &acirc; \\u00e2' => 'â',
     '\\^E &Ecirc; \\u00ca' => 'Ê',
     '\\^e &ecirc; \\u00ea' => 'ê',
     '\\^I &Icirc; \\u00ce' => 'Î',
     '\\^i &icirc; \\u00ee' => 'î',
     '\\^O &Ocirc; \\u00d4' => 'Ô',
     '\\^o &ocirc; \\u00f4' => 'ô',
     '\\^U &Ucirc; \\u00db' => 'Û',
     '\\^u &ucirc; \\u00fb' => 'û',
     '\\^Y &Ycirc; \\u0176' => 'Ŷ',
     '\\^y &ycirc; \\u0177' => 'ŷ',
     '\\~A &Atilde; \\u00c3' => 'Ã',
     '\\~a &atilde; \\u00e3' => 'ã',
     '\\~N &Ntilde; \\u00d1' => 'Ñ',
     '\\~n &ntilde; \\u00f1' => 'ñ',
     '\\~O &Otilde; \\u00d5' => 'Õ',
     '\\~o &otilde; \\u00f5' => 'õ',
     '\\"A &Auml; \\u00c4' => 'Ä',
     '\\"a &auml; \\u00e4' => 'ä',
     '\\"E &Euml; \\u00cb' => 'Ë',
     '\\"e &euml; \\u00eb' => 'ë',
     '\\"I &Iuml; \\u00cf' => 'Ï',
     '\\"i &iuml; \\u00ef' => 'ï',
     '\\"O &Ouml; \\u00d6' => 'Ö',
     '\\"o &ouml; \\u00f6' => 'ö',
     '\\"U &Uuml; \\u00dc' => 'Ü',
     '\\"u &uuml; \\u00fc' => 'ü',
     '\\"Y &Yuml; \\u0178' => 'Ÿ',
     '\\"y &yuml; \\u00ff' => 'ÿ',
     '\\cC &Ccedil; \\u00c7' => 'Ç',
     '\\cc &ccedil; \\u00e7' => 'ç',
     '\\AA &Aring; \\u00c5' => 'Å',
     '\\aa &aring; \\u00e5' => 'å',
     '\\/O &Oslash; \\u00d8' => 'Ø',
     '\\/o &oslash; \\u00f8' => 'ø',
     '\\uA &Abreve; \\u0102' => 'Ă',
     '\\ua &abreve; \\u0103' => 'ă',
     '\\uE \\u0114' => 'Ĕ',
     '\\ue \\u0115' => 'ĕ',
     '\\vS &Scaron; \\u0160' => 'Š',
     '\\vs &scaron; \\u0161' => 'š',
     '\\vZ &Zcaron; \\u017d' => 'Ž',
     '\\vz &zcaron; \\u017e' => 'ž',
     '\\HO \\u0150' => 'Ő',
     '\\Ho \\u0151' => 'ő',
     '\\HU \\u0170' => 'Ű',
     '\\Hu \\u0171' => 'ű',
     '\\AE &AElig; \\u00c6' => 'Æ',
     '\\ae &aelig; \\u00e6' => 'æ',
     '\\OE &OElig; \\u0152' => 'Œ',
     '\\oe &oelig; \\u0153' => 'œ',
     '\\ss &szlig; \\u00df' => 'ß',
     '\\DH &ETH; \\u00d0' => 'Ð',
     '\\dh &eth; \\u00f0' => 'ð',
     '\\TH &THORN; \\u00de' => 'Þ',
     '\\th &thorn; \\u00fe' => 'þ',
    )
=end

  class TextString < String
    attr_reader :original

    def self.unicode_escape(s)
      s.unpack('U*').map{ |i| "\\u" + i.to_s(16).rjust(4, '0') }.join
    end

    def self.unescape(s)
      # first pass: protect escaped \ % and &
      s = s.gsub(/\\(\\|%|\&)/) { unicode_escape($1) }
      # second pass: mnemonics
      s = s.gsub(/\\(..)/) { MNEMONICS[$1] ? MNEMONICS[$1] : $& }
      # third pass: html unescape
      s = HTMLEntities.new.decode(s)
      # fourth pass: unicode unescape
      s = unicode_unescape(s)
    end

    def self.unicode_unescape(s)
      s = s.gsub(/\\u([\da-fA-F]{4})/) {|m| [$1].pack("H*").unpack("n*").pack("U*") }
      s.gsub(/\\U([\da-fA-F]{8})/) { [$1].pack("H*").unpack("N*").pack("U*") }
    end

    def initialize(s)
      super(TextString.unescape(s))
      @original = s
    end
  end


end
