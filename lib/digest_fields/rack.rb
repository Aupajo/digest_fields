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
      validate_options!(options)
      @on_partial_content = options.fetch(:on_partial_content)
      @unencoded_digest = parse_unencoded_digest(options[:unencoded_digest])
    end

    def call(env)
      status, headers, body = @app.call(env)

      if status == 206
        mode = @unencoded_digest[:on_partial_content] || @on_partial_content
        case mode
        when :skip
          return [status, headers, body]
        when :warn
          Kernel.warn("Rack::DigestFields: Unencoded-Digest cannot be computed for 206 Partial Content")
          return [status, headers, body]
        when :raise
          raise PartialContentError, "Rack::DigestFields: Unencoded-Digest cannot be computed for 206 Partial Content"
        end
      end

      chunks = []
      body.each { |chunk| chunks << chunk }
      body.close if body.respond_to?(:close)
      buffered = chunks.join

      digest = ::DigestFields.digest(buffered, algorithms: @unencoded_digest[:algorithms])
      headers = headers.merge("Unencoded-Digest" => digest)

      [status, headers, [buffered]]
    end

    private

    def validate_options!(options)
      unknown = options.keys - KNOWN_OPTION_KEYS
      raise ArgumentError, "Unrecognised options: #{unknown.map(&:inspect).join(", ")}" if unknown.any?

      unless (options.keys & RECOGNISED_HEADER_KEYS).any?
        raise ArgumentError, "No digest headers configured. Provide at least one of: #{RECOGNISED_HEADER_KEYS.join(", ")}"
      end

      unless options.key?(:on_partial_content)
        raise ArgumentError, "on_partial_content is required (choose: :skip, :warn, or :raise)"
      end

      validate_on_partial_content!(options[:on_partial_content], context: "global")

      if options.key?(:unencoded_digest)
        config = options[:unencoded_digest]
        unless config == true || config.is_a?(Hash)
          raise ArgumentError, "unencoded_digest must be true or a Hash, got #{config.inspect}"
        end
      end

      return unless options[:unencoded_digest].is_a?(Hash)

      if options[:unencoded_digest].key?(:on_partial_content)
        validate_on_partial_content!(options[:unencoded_digest][:on_partial_content], context: "unencoded_digest")
      end

      if options[:unencoded_digest][:algorithms] == []
        raise ArgumentError, "algorithms cannot be empty"
      end
    end

    def validate_on_partial_content!(value, context:)
      return if VALID_ON_PARTIAL_CONTENT.include?(value)
      raise ArgumentError, "Invalid on_partial_content #{value.inspect} for #{context} (choose: :skip, :warn, or :raise)"
    end

    def parse_unencoded_digest(config)
      # Algorithms are snapshotted from the registry at middleware init time.
      # Changes to DigestFields.algorithms after initialization are not reflected.
      base_algorithms = ::DigestFields.algorithms.keys
      return {algorithms: base_algorithms} if config == true || config.nil? || config == {}

      {
        algorithms: config[:algorithms] || base_algorithms,
        on_partial_content: config[:on_partial_content]
      }
    end
  end
end
