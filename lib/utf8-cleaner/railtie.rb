# frozen_string_literal: true

module UTF8Cleaner
  # Railtie to bootstrap UTF8Cleaner::Middleware in a Rails application.
  class Railtie < Rails::Railtie
    initializer('utf8-cleaner.insert_middleware') do |app|
      app.config.middleware.insert_before(0, UTF8Cleaner::Middleware)
    end
  end
end
