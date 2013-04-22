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
       # Some of it might be old Windows code page
       string.encode(Encoding::UTF_8, Encoding::Windows_1250)
     end
    rescue EncodingError
     # Force it to UTF-8, throwing out invalid bits
     string.encode('UTF-16', 'UTF-8', :invalid => :replace, :replace => '').encode('UTF-8', 'UTF-16')
    end
  end
end
