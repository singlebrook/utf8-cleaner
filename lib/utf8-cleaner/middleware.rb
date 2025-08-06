# frozen_string_literal: true

require 'active_support/multibyte/unicode'

module UTF8Cleaner
  class Middleware
    SANITIZE_ENV_KEYS = %w[
      http_referer
      http_user_agent
      path_info
      query_string
      request_path
      request_uri
      http_cookie
    ].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(sanitize_env(env))
    end

    private

    include ActiveSupport::Multibyte::Unicode

    def sanitize_env(env)
      env = env.dup # Do not mutate the original
      sanitize_env_keys(env)
      sanitize_env_rack_input(env)
      env
    end

    def sanitize_env_keys(env)
      SANITIZE_ENV_KEYS.each do |key|
        next unless (value = env[key])
        env[key] = cleaned_string(value)
      end
    end

    def sanitize_env_rack_input(env)
      return unless env['rack.input']

      case env['content_type']
      when %r{\Aapplication/x-www-form-urlencoded}i
        # This data gets the full cleaning treatment
        input_data = read_input(env['rack.input'])
        return unless input_data

        cleaned_value = cleaned_string(input_data)
        env['rack.input'] = StringIO.new(cleaned_value)
      when %r{\Aapplication/json}i
        # This data only gets cleaning of invalid UTF-8 (e.g. from another charset)
        # but we do not URI-decode it.
        input_data = read_input(env['rack.input'])
        return unless input_data && !input_data.ascii_only?

        env['rack.input'] = StringIO.new(tidy_bytes(input_data))
      else
        # Do not process multipart/form-data since it may contain binary content.
        # Leave all other unknown content types alone.
      end
    end

    def read_input(input)
      return nil unless input

      data = input.read
      input.rewind if input.respond_to?(:rewind)
      data
    end

    def cleaned_string(value)
      return value if value.nil? || value.empty?

      value = value.to_s
      value = tidy_bytes(value) unless value.ascii_only?
      value = URIString.new(value).cleaned if value.include?('%')
      value
    end
  end
end
