module ABC
  
  class Meter
    attr_reader :symbol
    attr_reader :numerator
    attr_reader :denominator
    attr_reader :complex_numerator
    def initialize(arg1, arg2=nil, arg3=nil)
      if arg1 == :free        # free meter
        @symbol = :free
      elsif arg1 == :common   # common time
        @symbol = :common
        @numerator = 4
        @denominator = 4
        # TODO verify no arg2 or arg3
      elsif arg1 == :cut      # cut time
        @symbol = :cut
        @numerator = 2
        @denominator = 4
        # TODO verify no arg2 or arg3
      elsif arg1.is_a? Array  #complex meter
        @complex_numerator = arg1
        @numerator = arg1.reduce(:+)
        @denominator = arg2 
        # TODO verify arg2 is integer and no arg3
      else
        @numerator = arg1
        @denominator = arg2
        # TODO verify arg1 & arg2 are integers and no arg3
      end
    end
    def default_unit_note_length
      if symbol == :free || Rational(numerator, denominator) >= Rational(3, 4)
        Rational(1, 8)
      else
        Rational(1, 16)
      end
    end
  end

end
