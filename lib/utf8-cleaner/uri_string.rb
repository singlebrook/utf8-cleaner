module UTF8Cleaner
  class URIString
    attr_accessor :data

    def initialize(data)
      self.data = data
    end

    def encoded?
      data.include?('%')
    end

    def valid?
      URI.decode(data).valid_encoding?
    end
  end
end