module ABC
  
  class Meter
    attr_reader :symbol
    attr_reader :numerator
    attr_reader :denominator
    attr_reader :complex_numerator

    def initialize(*args)
      if args.count == 0
        @symbol = :free
      elsif args.count == 1
        @symbol = args[0]
        if @symbol == :free
          # free meter
        elsif @symbol == :common
          # common time
          @numerator = 4
          @denominator = 4
        elsif @symbol == :cut
          # cut time
          @numerator = 2
          @denominator = 4
        else
          raise ArgumentError.new "Unrecognized meter: #{args[0]}"
        end
      elsif args.count == 2 && args[1].is_a?(Integer)
        @numerator = args[0]
        @denominator = args[1]
        if @numerator.is_a? Integer
          # simple meter eg 6/8          
        elsif @numerator.is_a?(Array) && @numerator.all? {|x| x.is_a? Integer }
          # complex meter eg (3+2+3)/8
          @complex_numerator = @numerator
          @numerator = @numerator.reduce(:+)
        else
          raise ArgumentError.new "Unrecognized meter: #{args[0]}/#{args[1]}"
        end
      else
        raise ArgumentError.new "Wrong number of arguments: #{args.count} for 0-2"
      end
    end

    def default_unit_note_length
      if symbol == :free || measure_length >= Rational(3, 4)
        Rational(1, 8)
      else
        Rational(1, 16)
      end
    end

    def measure_length
      Rational(numerator, denominator) unless symbol == :free
    end
  end

end
