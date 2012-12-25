class Hash

    # convenience method for building hashes that associate several keys to the same value
    # split_keys("A B C D" => 1) returns { 'A' => 1, 'B' => 1, 'C' => 1, 'D' => 1 }
    def self.split_keys(hash)
      list = hash.keys.map { |keygroup| keygroup.split.map { |key| [key, hash[keygroup]] } }
      Hash[*list.flatten]
    end

end
