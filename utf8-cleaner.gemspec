# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'utf8-cleaner/version'

Gem::Specification.new do |gem|
  gem.name          = "utf8-cleaner"
  gem.version       = UTF8Cleaner::VERSION
  gem.authors       = ["Leon Miller-Out"]
  gem.email         = ["leon@singlebrook.com"]
  gem.description   = %q{Removes invalid UTF8 characters from the URL and other env vars}
  gem.summary       = %q{Prevent annoying error reports of "invalid byte sequence in UTF-8"}
  gem.homepage      = "https://github.com/singlebrook/utf8-cleaner"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rake"
  gem.add_development_dependency "guard"
  gem.add_development_dependency "guard-rspec"
  gem.add_development_dependency "rspec"
end
