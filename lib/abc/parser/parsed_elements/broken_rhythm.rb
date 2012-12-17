module ABC
  class BrokenRhythm
    
    def initialize(symbols)
      @symbols = symbols
    end

    # direction = '<' or '>'; which note's timing are you changing?
    def change(direction) 
      x = Rational(1, 2 ** @symbols.length)
      @symbols[0] == direction ? x : 2 - x
      # 2-x means 1 + (1-x): original time (=1)
      # plus the time that's left after shortening the other note (=1-x)
    end

  end
end
