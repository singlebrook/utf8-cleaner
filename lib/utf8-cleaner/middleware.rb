module UTF8Cleaner
  class Middleware

    SANITIZE_ENV_KEYS = [
     "HTTP_COOKIE",     # bad cookie encodings kill rack: https://github.com/rack/rack/issues/225
     "HTTP_REFERER",
     "PATH_INFO",
     "QUERY_STRING",
     "REQUEST_PATH",
     "REQUEST_URI",
    ]

    def initialize(app)
     @app = app
    end

    def call(env)
     @app.call(sanitize_env(env))
    end

    private

    def sanitize_env(env)
     SANITIZE_ENV_KEYS.each do |key|
       next unless value = env[key]
       value = sanitize_string(URI.decode(value))
       env[key] = URI.encode(value)
     end
     ["HTTP_COOKIE"].each do |key|
       next unless value = env[key]
       fixed = sanitize_string(value)
       env[key] = fixed if fixed
     end
     env
    end

    def sanitize_string(string)
      return string unless string.is_a? String

      # Try it as UTF-8 directly
      cleaned = string.dup.force_encoding('UTF-8')
      if cleaned.valid_encoding?
        cleaned
      else
        utf8clean(string)
      end
    rescue EncodingError
      utf8clean(string)
    end

    def utf8clean(string)
      # Force it to UTF-8, throwing out invalid bits
      if RUBY_VERSION >= "1.9.3"
        # These converters don't exist in 1.9.2
        string.encode('UTF-16', 'UTF-8', :invalid => :replace, :replace => '').encode('UTF-8', 'UTF-16')
      else
        string.chars.select{|i| i.valid_encoding?}.join
      end
    end
  end
end
