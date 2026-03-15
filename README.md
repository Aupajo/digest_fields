# Digest Fields

[![Gem Version](https://badge.fury.io/rb/digest_fields.svg)](https://badge.fury.io/rb/digest_fields)

Support for `Content-Digest` and `Repl-Digest` header digests that follows the [RFC 9530](https://www.rfc-editor.org/rfc/rfc9530.html) specification.

## Usage

### Rack middleware

`Rack::DigestFields` automatically computes and injects `Unencoded-Digest` response headers.

> [!NOTE]
> `Unencoded-Digest` is defined in an IETF draft ([draft-ietf-httpbis-unencoded-digest](https://datatracker.ietf.org/doc/draft-ietf-httpbis-unencoded-digest/)) that has not yet been standardised. Breaking changes to the header name, wire format, or semantics are unlikely — current feedback on the draft focuses on security considerations rather than the core design — but it is possible before the RFC is finalised.

```ruby
# config.ru
require "digest_fields/rack"

use Rack::DigestFields,
  on_partial_content: :raise,  # required: :raise | :warn | :skip
  unencoded_digest: true        # uses default algorithms (sha-256, sha-512)
```

With algorithm override:

```ruby
use Rack::DigestFields,
  on_partial_content: :skip,
  unencoded_digest: {
    algorithms: %w[sha-256],
    on_partial_content: :warn  # overrides global for this header
  }
```

In Rails, insert before `Rack::Sendfile` to ensure the middleware sees the raw response body before any transformation:

```ruby
config.middleware.insert_before Rack::Sendfile, Rack::DigestFields,
  on_partial_content: :raise,
  unencoded_digest: true
```

`on_partial_content` is required with no default — `206 Partial Content` responses cannot correctly produce `Unencoded-Digest` (it requires the full unencoded representation). The three behaviours are:

| Value | Behaviour |
|---|---|
| `:raise` | Raise `Rack::DigestFields::PartialContentError` |
| `:warn` | Emit a warning and omit the header |
| `:skip` | Omit the header silently |

### Library

```ruby
DigestFields.digest(body)
# => "sha-256=:X48E9qOok...:, sha-512=:jas48SD...:"

DigestFields.digest(body, algorithms: "sha-256")
# => "sha-256=:X48E9qOok...:

DigestFields.digest(body, algorithms: %w[sha-256 sha-512])
# => "sha-256=:X48E9qOok...:, sha-512=:jas48SD...:"
```

### Custom Algorithms

`sha-512` and `sha-256` are supported.

The spec's [deprecated hash algorithms](https://www.iana.org/assignments/http-digest-hash-alg/http-digest-hash-alg.xhtml) are intentionally not supported, but you can add your own support if you need to:

```ruby
# Register a custom algorithm
DigestFields.algorithms.add("md5", ->(body) { Digest::MD5.base64digest(body) })

DigestFields.digest(body, algorithms: %w[md5 sha-512])
# => "md5=:...:, sha-512=:...:, "
```

## Installation

Add to your project's `Gemfile`:

```bash
bundle add digest_fields
```

Or, install gem directly:

```bash
gem install digest_fields
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aupajo/digest_fields. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/aupajo/digest_fields/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DigestFields project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/aupajo/digest_fields/blob/main/CODE_OF_CONDUCT.md).
