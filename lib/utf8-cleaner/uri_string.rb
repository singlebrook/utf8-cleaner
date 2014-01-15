module UTF8Cleaner
  class URIString
    attr_accessor :data

    def initialize(data)
      self.data = data
    end

    def cleaned
      if valid?
        data
      else
        encoded_char_array.join
      end
    end

    def encoded?
      data.include?('%')
    end

    def valid?
      valid_uri_encoded_utf8(data)
    end

    private

    # Returns an array of valid URI-encoded UTF-8 characters.
    def encoded_char_array
      char_array = []
      index = 0

      while (index < data.length) do
        char = data[index]

        if char == '%'
          # Skip the next two characters, which are the encoded byte
          # indicates by this %. (We'll change this later for multibyte characters.)
          skip_next = 2

          # How long is this character?
          first_byte = '0x' + (data[index + 1] + data[index + 2]).upcase
          bytes = utf8_char_length_in_bytes(first_byte)

          # Grab the specified number of encoded bytes
          utf8_char_encoded_bytes = next_n_bytes_from(index, bytes)

          # Did we get the right number of bytes?
          if utf8_char_encoded_bytes.length == bytes

            # We did. Is it a valid character?
            utf8_char_encoded = utf8_char_encoded_bytes.join

            if valid_uri_encoded_utf8(utf8_char_encoded)
              # It's valid!
              char_array << utf8_char_encoded

              # If we're dealing with a multibyte character, skip more than two
              # of the next characters, which have already been processed.
              skip_next = bytes * 3 - 1
            end
          end
          index += skip_next
        else
          # This was not an encoded character, so just add it and move to the next.
          char_array << char
        end
        index += 1
      end

      char_array
    end

    def valid_uri_encoded_utf8(string)
      string.match(/^([!#$&-;=?-\[\]_a-z~]|%[0-9a-fA-F]{2})+$/) &&
      URI.decode(string).force_encoding('UTF-8').valid_encoding?
    end

    # Grab the next num_bytes URI-encoded bytes from the raw character array.
    # Returns an array like ['%E2', '%9C', '%93']
    def next_n_bytes_from(index, num_bytes)
      return [] if data.length < index + (3 * num_bytes)

      num_bytes.times.map do |n|
        # Look for percent signs in the right places
        pct_index = index + (3 * n)
        if data[pct_index] == '%'
          byte = data[pct_index + 1..pct_index + 2]
        else
          # An expected percent sign was missing. The whole character is invalid.
          return []
        end
        '%' + byte
      end
    end

    # If the first byte is between 0xC0 and 0xDF, the UTF-8 character has two bytes;
    # if it is between 0xE0 and 0xEF, the UTF-8 character has 3 bytes;
    # and if it is 0xF0 and 0xFF, the UTF-8 character has 4 bytes.
    # first_byte is a string like "0x13"
    def utf8_char_length_in_bytes(first_byte)
      if first_byte.hex < 'C0'.hex
        1
      elsif first_byte.hex < 'DF'.hex
        2
      elsif first_byte.hex < 'EF'.hex
        3
      else
        4
      end
    end

  end
end
