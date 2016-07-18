# CHANGELOG

## v0.2.5

* MIT license specified in gemspec

## v0.2.4

* Rails 5 support (just fixed deprecations)

## v0.2.3

* Don't URI-decode JSON in the request body

## v0.2.2

* Handle an exception related to mixed encodings in a single string

## v0.2.1

* Cleans request body when content type is application/json

## v0.2.0

* Removes invalid %-encodings like "%x", "%0z", and "%" if not followed by two hex chars

## v0.1.1

* Now cleans HTTP_USER_AGENT
* Replaces some Windows (ISO-8859-1 and CP1252) characters with UTF8 equivalents

## v0.1.0

Broken.
