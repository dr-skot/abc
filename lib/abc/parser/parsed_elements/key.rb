module ABC

  # A Key is initialized with a tonic eg 'C#', a mode eg 'minor' or 'Dorian' or '' (= major), 
  # and optional extra accidentals eg { 'C' => 1, 'E' => -1, 'B' => 0 } (ie C#, Eb, B natural)
  # Key#signature returns a hash mapping note names (eg 'C', 'A') to 1 or -1 (sharp or flat)

  class Key

    # convenience method for building hashes that associate several keys to the same value
    # split_keys("A B C D" => 1) returns { 'A' => 1, 'B' => 1, 'C' => 1, 'D' => 1 }
    def self.split_keys(hash)
      list = hash.keys.map { |keygroup| keygroup.split.map { |key| [key, hash[keygroup]] } }
      Hash[*list.flatten]
    end

    def self.three_letter_index(list)
      list.inject({}) { |result, item| result[item[0,3]] = item; result }
    end
    
    # maps <tonic><mode> to signature
    SIGNATURES = split_keys(
      "C# A#m G#mix D#dor E#phr F#lyd B#loc" => split_keys("C D E F G A B" => 1),
      "F# D#m C#mix G#dor A#phr Blyd E#loc" => split_keys("C D E F G A" => 1),
      "B G#m F#mix C#dor D#phr Elyd A#loc" => split_keys("C D F G A" => 1),
      "E C#m Bmix F#dor G#phr Alyd D#loc" => split_keys("C D F G" => 1),
      "A F#m Emix Bdor C#phr Dlyd G#loc" => split_keys("C F G" => 1),
      "D Bm Amix Edor F#phr Glyd C#loc" => split_keys("C F" => 1),
      "G Em Dmix Ador Bphr Clyd F#loc" => { "F" => 1 },
      "C Am Gmix Ddor Ephr Flyd Bloc" => {},
      "F Dm Cmix Gdor Aphr Bblyd Eloc" => split_keys("B" => -1),
      "Bb Gm Fmix Cdor Dphr Eblyd Aloc" => split_keys("E B" => -1),
      "Eb Cm Bbmix Fdor Gphr Ablyd Dloc" => split_keys("E A B" => -1),
      "Ab Fm Ebmix Bbdor Cphr Dblyd Gloc" => split_keys("D E A B" => -1),
      "Db Bbm Abmix Ebdor Fphr Gblyd Cloc" => split_keys("D E G A B" => -1),
      "Gb Ebm Dbmix Abdor Bbphr Cblyd Floc" => split_keys("C D E G A B" => -1),
      "Cb Abm Gbmix Dbdor Ebphr Fblyd Bbloc" => split_keys("C D E F G A B" => -1),
      "HP Hp" => { 'C' => 1, 'F' => 1, 'G' => 0 },
    )

    MODES = three_letter_index("major minor ionian aeolean mixolydian dorian phrygian lydian locrian".split)

    # static method for convenience
    def self.signature(tonic, mode="", extra_accidentals={})
      self.new(tonic, mode, extra_accidentals).signature      
    end

    attr_reader :extra_accidentals
    attr_accessor :clef

    def initialize(tonic_or_hp=nil, mode="", extra_accidentals={})
      @tonic_or_hp = tonic_or_hp
      @original_mode = mode
      @extra_accidentals = extra_accidentals
    end

    def tonic
      if highland_pipes?
        nil
      else
        @tonic_or_hp
      end
    end

    def mode
      if !@mode
        if @tonic_or_hp == nil
          @mode = nil
        else
          mode = @original_mode.downcase[0,3]
          mode = "maj" if mode == ""
          mode = "min" if mode == "m"
          @mode = MODES[mode]
        end
      end
      @mode
    end

    def short_mode
      if !@short_mode
        mode = @original_mode.downcase[0,3]
        mode = "" if mode == "maj" || mode == "ion"
        mode = "m" if mode == "min" || mode == "aeo"
        @short_mode = mode
      end
      @short_mode
    end

    def base_signature
      if !@base_signature
        @base_signature = SIGNATURES["#{@tonic_or_hp}#{short_mode}"] || {}
      end
      @base_signature
    end
    
    def signature
      base_signature.merge(extra_accidentals)
    end
    
    def clef
      @clef || Clef::DEFAULT
    end

    def highland_pipes?
      @tonic_or_hp == "Hp" || @tonic_or_hp == "HP"
    end

    def show_accidentals?
      @tonic_or_hp != "HP"
    end

    NONE = Key.new

  end

end