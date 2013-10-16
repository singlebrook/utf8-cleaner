module UTF8Cleaner
  class URIString
    attr_accessor :data

    def initialize(data)
      self.data = data
    end

    def cleaned
      encoded_char_array.join
    end

    def encoded?
      data.include?('%')
    end

    def valid?
      URI.decode(data).valid_encoding?
    end

    private

    def encoded_char_array
      pct = '%'
      skip_next = 0
      index = -1
      char_array = []
      data.chars.each do |char|
        index += 1
        if skip_next > 0
          skip_next -= 1
          next
        end
        if char == pct
          # If the first byte is between 0xC0 and 0xDF, the UTF-8 character has two bytes;
          # if it is between 0xE0 and 0xEF, the UTF-8 character has 3 bytes;
          # and if it is 0xF0 and 0xFF, the UTF-8 character has 4 bytes.
          first_byte = '0x' + (data.chars[index + 1] + data.chars[index + 2]).upcase
          if first_byte.hex < 'C0'.hex
            bytes = 1
          elsif first_byte.hex < 'DF'.hex
            bytes = 2
          elsif first_byte.hex < 'EF'.hex
            bytes = 3
          else
            bytes = 4
          end

          valid_num_bytes = true
          #puts "processing " + data.chars[index..-1].join
          if data.chars.length < index + (3 * bytes)
            valid_num_bytes = false
          else
            utf8_char_encoded_bytes = bytes.times.map do |n|
              pct_index = index + (3 * n)
              if data.chars[pct_index] == '%'
                byte = data.chars[pct_index + 1..pct_index + 2].join('')
              else
                valid_num_bytes = false
                break
              end
              pct + byte
            end
          end

          if valid_num_bytes
            utf8_char_encoded = utf8_char_encoded_bytes.join

            if URI.decode(utf8_char_encoded).valid_encoding?
              skip_next = bytes * 3 - 1
              char_array << utf8_char_encoded
            else
              skip_next = 2
            end
          else
            skip_next = 2
          end
        else
          skip_next = 0
          char_array << char
        end
        #puts "skip_next: #{skip_next}"
      end

      char_array
    end
  end
end