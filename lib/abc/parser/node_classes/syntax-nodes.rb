# TODO tune.overlays? might also be useful if there are overlays in any measures
# TODO maybe also a list of these measures as measures_with_overlays
# TODO dotted bar should not make a new measure
# TODO data structure: tunes[t].measures[m].notes[n] note can be: note, chord, rest, !measure rest! which can make the measure several measures long
# TODO data structure: tunes[t].measures[m].items[i] item is any of the above plus spacer, dotted bar and fields

module ABC

  class ABCSection < ABCNode
  end

  class TypesetText < ABCSection
  end

  class FreeText < ABCSection
  end

  # BASICS

  class ABCString < ABCNode
  end

end
