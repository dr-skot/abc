module ABC
  class MidiVoice
    
    attr_accessor :voice
    attr_reader :instrument
    attr_reader :bank
    attr_reader :mute

    alias_method :mute?, :mute

    def initialize(voice, instrument, bank, mute)
      @voice = voice
      @instrument = instrument
      @bank = bank || 1
      @mute = mute
    end

  end
end
