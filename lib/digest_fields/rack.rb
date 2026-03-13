require "rack"
require "digest_fields"

module Rack
  class DigestFields
    class PartialContentError < StandardError; end

    VALID_ON_PARTIAL_CONTENT = %i[skip warn raise].freeze
    RECOGNISED_HEADER_KEYS = %i[unencoded_digest].freeze
    KNOWN_OPTION_KEYS = (RECOGNISED_HEADER_KEYS + [:on_partial_content]).freeze

    def initialize(app, **options)
      @app = app
    end

    def call(env)
      @app.call(env)
    end
  end
end
