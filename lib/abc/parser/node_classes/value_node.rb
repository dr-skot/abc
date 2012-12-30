module ABC
  class ValueNode < ABCNode
    def christen
      value.christen(self) if value.respond_to? :christen
    end
    
  end
end
