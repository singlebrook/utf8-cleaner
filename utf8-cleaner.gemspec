# frozen_string_literal: true

require_relative 'lib/utf8-cleaner/version'

Gem::Specification.new do |gem|
  gem.name          = 'utf8-cleaner'
  gem.version       = UTF8Cleaner::VERSION
  gem.authors       = ['Leon Miller-Out']
  gem.email         = ['leon@singlebrook.com']
  gem.description   = 'Rack middleware to remove invalid UTF8 characters from web requests.'
  gem.summary       = 'Prevent annoying "invalid byte sequence in UTF-8" errors.'
  gem.homepage      = 'https://github.com/singlebrook/utf8-cleaner'
  gem.license       = 'MIT'

  gem.files         = Dir['lib/**/*'] + %w[README.md LICENSE.txt]
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 2.4'

  gem.add_dependency 'activesupport'
  gem.add_dependency 'rack', '>= 3.0'

  gem.metadata['rubygems_mfa_required'] = 'true'
end
