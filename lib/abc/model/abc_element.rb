module ABC

  # Any element that appears in the body of an abc tune. Either a MusicElement
  # or one of the punctuation markers that indicate ties, slurs, beam breaks, and linebreaks. 
  # See #type.
  class ABCElement
    
    # _symbol_ What type of element is this?
    # Possible values are those for MusicElement and Field, plus
    # +:beam_break+::        whitespace between notes in the original abc code; 
    #                        notes with this element between them should not be beamed together
    # +:tie+::               "-" between notes in the original code, meaning the notes are tied
    # +:dotted_tie+::        ".-" in the original code, meaning tie the notes with a dotted tie  
    # +:start_slur+::        "(" in the original code, meaning start a new slur at the next note
    # +:start_dotted_slur+:: ".(" in the original, meaning start a dotted slur at the next note
    # +:end_slur+::          ")" in the original, meaning the most recently started slur 
    #                        (dotted or otherwise) ends at the preceding note
    # +:code_linebreak+::    marks where a linebreak occured in the original abc code
    # +:score_linebreak+::   an explicit linebreak in the score, indicated by "$" in the code 
    #                        (or "!" in some dialects)
    # Elements indicating slurs, ties, and beam breaks can be ignored in most applications
    # because this information is more conveniently available as attributes of the notes 
    # involved. See NoteOrChord.
    attr_reader :type

    # _string_ In which part of a multipart tune does this element appear?
    attr_accessor :part

    # _string_ In which voice of a multivoice tune does this element occur?
    attr_accessor :voice

    # Creates a new element of type <code>type</code>.
    def initialize(type)
      @type = type
    end

    # An ABCElement with type <code>:code_linebreak</code>, 
    # corresponding to a linebreak in the original abc code.
    CODE_LINEBREAK = ABCElement.new(:code_linebreak)

    # An ABCElement with type <code>:score_linebreak</code>,
    # representing an explicit linebreak specified by the linebreak symbol <code>$</code> 
    # (or <code>!</code> in some dialects).
    SCORE_LINEBREAK = ABCElement.new(:score_linebreak)

  end
end
