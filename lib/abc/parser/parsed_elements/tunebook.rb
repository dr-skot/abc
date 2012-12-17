module ABC

  class Tunebook < HeaderedSection
    attr_reader :sections

    def sections
      @sections ||= children.select { |v| !v.is_a?(Header) }
    end

    def tunes
      @tunes ||= children(Tune)
    end

    def tune(refnum)
      tunes.select { |f| f.refnum == refnum }.last
    end

    def postprocess
      tunes.each do |tune| 
        tune.master_node = self
        tune.postprocess
      end
      self
    end

  end
end
