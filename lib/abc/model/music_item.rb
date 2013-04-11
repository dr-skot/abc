module ABC
  
  # Base class for music elements that are considered _items_.
  #
  # Subclasses are EmbellishedUnit, Field, TupleMarker, VariantEnding
  # For example in the tune fragment "(ab)c-d\n[M:6/8]ef",
  # 
  class MusicItem < MusicElement
  end

end
