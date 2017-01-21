require 'active_support/multibyte/unicode'

module UTF8Cleaner
  class Middleware

    SANITIZE_ENV_KEYS = [
     "HTTP_REFERER",
     "HTTP_USER_AGENT",
     "PATH_INFO",
     "QUERY_STRING",
     "REQUEST_PATH",
     "REQUEST_URI",
     "HTTP_COOKIE",
     "SERVER_NAME",
     "HTTP_HOST"
    ]

    def initialize(app)
     @app = app
    end

    def call(env)
     @app.call(sanitize_env(env))
    end

    private

    include ActiveSupport::Multibyte::Unicode

    def sanitize_env(env)
      sanitize_env_keys(env)
      sanitize_env_rack_input(env)
      env
    end

    def sanitize_env_keys(env)
      SANITIZE_ENV_KEYS.each do |key|
        next unless value = env[key]
        env[key] = cleaned_string(value)
      end
    end

    def sanitize_env_rack_input(env)
      case env['CONTENT_TYPE']
      when 'application/x-www-form-urlencoded'
        # This data gets the full cleaning treatment
        cleaned_value = cleaned_string(env['rack.input'].read)
        env['rack.input'] = StringIO.new(cleaned_value) if cleaned_value
        env['rack.input'].rewind
      when 'application/json'
        # This data only gets cleaning of invalid UTF-8 (e.g. from another charset)
        # but we do not URI-decode it.
        rack_input = env['rack.input'].read
        if rack_input && !rack_input.ascii_only?
          env['rack.input'] = StringIO.new(tidy_bytes(rack_input))
        end
        env['rack.input'].rewind
      when 'multipart/form-data'
        # Don't process the data since it may contain binary content
      else
        # Unknown content type. Leave it alone
      end
    end

    def cleaned_string(value)
      value = tidy_bytes(value) unless value.ascii_only?
      value = URIString.new(value).cleaned if value.include?('%')
      value
    end
  end
end
