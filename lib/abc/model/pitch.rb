module ABC

  # Represents a musical pitch.
  # 
  # The pitch is defined by a letter (A B C D E F or G), an optional accidental, and an octave
  # number.
  #
  # A synonym for #letter is #note.
  # 
  # Accidentals are represented as integers ranging from -2 (double flat) to 2 (double sharp),
  # specifying the pitch adjustment in half steps.
  # Notice that a value of <code>nil</code> means no accidental is specified, 
  # whereas 0 indicates an explicit natural.
  #
  # Octave 0 begins at middle C. Higher octaves are numbered 1, 2, etc, and lower ones -1, -2,
  # etc.
  #
  # These are the basic elements for an individual note, but in the context of a musical
  # passage the pitch may be affected by the key signature, accidentals applied earlier
  # in the measure, or transpositions indicated by the clef. The Pitch
  # object has attributes for these contextual elements: #key_signature, #local_accidentals,
  # and #clef. After these have been set, #height will return the actual pitch.
  #
  #   b = Pitch.new('B')
  #   b.height.should == 11
  #   b.key_signature = {'B'=>-1} # key of F
  #   b.height.should == 10
  #   b.local_accidentals = {'B'=>0} # natural applied earlier in measure
  #   b.height.should == 11 # local natural overrides key sig
  #   
  #   low_b = Pitch.new('B', :octave => -1)
  #   low_b.height.should == -1
  #   
  #   b_natural = Pitch.new('B', :accidental => 0)
  #   b_natural.key_signature = {'B'=>-1}
  #   b_natural.height.should == 11 # explicit natural overrides key sig
  class Pitch

    # _string_ letter name of the note, one of A B C D E F G
    attr_reader :letter
    alias_method :note, :letter

    # _integer_ -1 flat, 0 natural, 1 sharp, nil none, -2 dbl flat, 2 dbl sharp  
    attr_reader :accidental

    # _integer_ octave of the pitch, where middle C starts octave 0; default 0 
    attr_reader :octave

    # <em>{string=>integer}</em> accidentals imposed by the key signature;
    # note letters are mapped to accidental values, eg <code>{'B'=>-1}</code> for key of F
    attr_accessor :key_signature

    # <em>{string=>integer}</em> or <em>{[string,integer]=>integer}</em> 
    # accidentals imposed locally, eg because of accidentals
    # on previous notes in the measure
    attr_accessor :local_accidentals

    # _Clef_ the clef on which this note appears
    attr_accessor :clef

    # Makes a new Pitch with #letter <code>letter</code> and <code>opts</code> as follows:
    # +:octave+:: _integer_ #octave; default 0 
    # +:accidental+:: _integer_ #accidental; default <code>nil</code>
    def initialize(letter, opts = {})
      @letter = letter.upcase
      @octave = opts[:octave] || 0
      @accidental = opts[:accidental]
      @local_accidentals = {}
    end

    def key_signature
      @key_signature ||= {}
    end

    # _integer_ The relative height of this note in its octave, in half steps above C.
    # This takes into account the note #letter, the #effective_accidental,
    # and any #transposition imposed by the #clef. Will be an integer from 0 to 11.
    def height_in_octave
      height % 12
    end

    # _integer_ The absolute height of this note in half steps, where middle C is zero.
    # This takes into account the note #letter, the #effective_accidental,
    # any #transposition imposed by the #clef, and the #effective_octave.
    def height
      12 * effective_octave + "C D EF G A B".index(letter) + effective_accidental + transposition
    end

    # _integer_ The accidental applied to this pitch in context. This is either
    # - an explicit #accidental (passed to the constructor)
    # - a local accidental, eg one applied to an earlier note in the measure
    # - an accidental from the key signature
    # or 0 if none of these are found
    def effective_accidental
      accidental || local_accidental || key_signature[letter] || 0
    end

    # _integer_ Octave of the pitch in context. This is the #octave value passed to the
    # constructor plus any octave shift imposed by the #clef.
    def effective_octave
      @octave + (clef ? clef.octave_shift : 0)
    end

    # _self_ Sets the #key_signature and the #local_accidentals.
    def set_accidentals(signature, locals)
      self.key_signature = signature
      self.local_accidentals = locals
      self
    end

    private

    # _integer_ The local accidental for this note, if any.
    def local_accidental
      local_accidentals[note] || local_accidentals[[letter, octave]]
    end

    # _integer_ The transposition imposed by the #clef, if any. Otherwise 0.
    def transposition
      clef ? clef.transpose : 0
    end

  end

end
