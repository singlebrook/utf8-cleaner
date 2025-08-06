# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'utf8-cleaner/version'

Gem::Specification.new do |gem|
  gem.name          = "utf8-cleaner"
  gem.version       = UTF8Cleaner::VERSION
  gem.authors       = ["Leon Miller-Out", "Shane Cavanaugh"]
  gem.email         = ["leon@singlebrook.com", "shane@shanecav.net"]
  gem.description   = %q{Removes invalid UTF8 characters from the URL and other env vars}
  gem.summary       = %q{Prevent annoying error reports of "invalid byte sequence in UTF-8"}
  gem.homepage      = "https://github.com/singlebrook/utf8-cleaner"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 2.3.0"

  gem.add_dependency 'activesupport'

  gem.add_development_dependency "rake"
  gem.add_development_dependency "listen", "3.0.8"
  gem.add_development_dependency "guard"
  gem.add_development_dependency "guard-rspec"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rack"
end
