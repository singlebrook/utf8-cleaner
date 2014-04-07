module UTF8Cleaner
  class Middleware

    SANITIZE_ENV_KEYS = [
     "HTTP_REFERER",
     "PATH_INFO",
     "QUERY_STRING",
     "REQUEST_PATH",
     "REQUEST_URI",
     "HTTP_COOKIE"
    ]

    def initialize(app)
     @app = app
    end

    def call(env)
     @app.call(sanitize_env(env))
    end

    private

    def sanitize_env(env)
      sanitize_env_keys(env)
      sanitize_env_rack_input(env)
      env
    end

    def sanitize_env_keys(env)
      SANITIZE_ENV_KEYS.each do |key|
        next unless value = env[key]
        cleaned_value = cleaned_uri_string(value)
        env[key] = cleaned_value if cleaned_value
      end
    end

    def sanitize_env_rack_input(env)
      if value = env['rack.input'].read
        cleaned_value = cleaned_uri_string(value)
        env['rack.input'].reopen(cleaned_value) if cleaned_value
      end
      env['rack.input'].rewind
    end

    def cleaned_uri_string(value)
      if value.include?('%')
        URIString.new(value).cleaned
      end
    end
  end
end
