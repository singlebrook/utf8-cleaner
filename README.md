# UTF8Cleaner

Removes invalid UTF-8 characters from the environment so that your app doesn't choke
on them. This prevents errors like "invalid byte sequence in UTF-8".

## Installation

Add this line to your application's Gemfile:

    gem 'utf8-cleaner'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install utf8-cleaner

If you're not running Rails, you'll have to add the middleware to your config.ru:

    require 'uf8-cleaner'
    use UTF8Cleaner::Middleware

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
