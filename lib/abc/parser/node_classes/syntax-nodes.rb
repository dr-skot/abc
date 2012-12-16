# TODO tune.overlays? might also be useful if there are overlays in any measures
# TODO maybe also a list of these measures as measures_with_overlays
# TODO dotted bar should not make a new measure
# TODO data structure: tunes[t].measures[m].notes[n] note can be: note, chord, rest, !measure rest! which can make the measure several measures long
# TODO data structure: tunes[t].measures[m].items[i] item is any of the above plus spacer, dotted bar and fields

module ABC

  DEFAULT_USER_DEFINED_SYMBOLS = {
    '.' => Decoration.new('staccato', '.'),
    '~' => Decoration.new('roll', '~'),
    'T' => Decoration.new('trill', 'T'),
    'H' => Decoration.new('fermata', 'H'),
    'L' => Decoration.new('emphasis', 'L'),
    'M' => Decoration.new('lowermordent', 'M'),
    'P' => Decoration.new('uppermordent', 'P'),
    'S' => Decoration.new('segno', 'S'),
    'O' => Decoration.new('coda', 'O'),
    'u' => Decoration.new('upbow', 'u'),
    'v' => Decoration.new('downbow', 'v'),
  }

  class ABCSection < ABCNode
  end

  class TypesetText < ABCSection
  end

  class FreeText < ABCSection
  end

  # FIELDS

  class TuneLineBreak < ABCNode
  end

  # NOTES AND RESTS

  class BrokenRhythm < MusicNode
  end

  # OVERLAY DELIMITER
  class OverlayDelimiter < MusicNode
  end

  # BASICS

  class ABCString < ABCNode
  end

end
