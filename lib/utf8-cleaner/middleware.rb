require 'active_support/multibyte/unicode'

module UTF8Cleaner
  class Middleware
    VALID_METHODS = [:clean, :raise].freeze

    def initialize(app, method)
      unless VALID_METHODS.include?(method.to_sym)
        raise ArgumentError, 'Method must be either :clean or :raise'
      end

      @app = app
      @method = method.to_sym
    end

    def call(env)
      case @method
      when :clean
        @app.call(Methods::CleanMethod.new(env).sanitize_env)
      when :raise
        raise
      end
    end
  end
end
