require "digest_fields/rack"

RSpec.describe Rack::DigestFields do
  # Fixture body and known digest values from draft-ietf-httpbis-unencoded-digest Section 6
  let(:body_string) { "An unexceptional string\n" }
  let(:sha256_value) { "5Bv3NIx05BPnh0jMph6v1RJ5Q7kl9LKMtQxmvc9+Z7Y=" }
  let(:sha512_value) { "WjyMuMD9EI/v0RoJchcevbo6lF498VyE9564OgXf+98iJptoSvb1Czo9uVJu2bVU/tOv90huiMG3+YaMX1kipw==" }

  def stub_app(status: 200, body: nil, headers: {})
    response_body = body || [body_string]
    ->(_env) { [status, {"content-type" => "text/plain"}.merge(headers), response_body] }
  end

  def build_middleware(app = nil, **options)
    app ||= stub_app
    Rack::DigestFields.new(app, **options)
  end

  describe ".new (validation)" do
    it "raises ArgumentError when no header key is configured" do
      expect { build_middleware(on_partial_content: :raise) }
        .to raise_error(ArgumentError, /No digest headers configured/)
    end

    it "raises ArgumentError for an unrecognised option key with no recognised header" do
      # repr_digest is not a recognised key in v1 — hits the unknown-key check
      expect { build_middleware(on_partial_content: :raise, repr_digest: true) }
        .to raise_error(ArgumentError, /Unrecognised options/)
    end

    it "raises ArgumentError for an unrecognised option key alongside a recognised header" do
      expect { build_middleware(on_partial_content: :raise, unencoded_digest: true, typo: true) }
        .to raise_error(ArgumentError, /Unrecognised options/)
    end

    it "raises ArgumentError when on_partial_content is omitted" do
      expect { build_middleware(unencoded_digest: true) }
        .to raise_error(ArgumentError, /on_partial_content is required/)
    end

    it "raises ArgumentError for an invalid global on_partial_content value" do
      expect { build_middleware(on_partial_content: :ignore, unencoded_digest: true) }
        .to raise_error(ArgumentError, /:ignore/)
    end

    it "raises ArgumentError for an invalid per-header on_partial_content value" do
      expect do
        build_middleware(
          on_partial_content: :raise,
          unencoded_digest: {algorithms: %w[sha-256], on_partial_content: :ignore}
        )
      end.to raise_error(ArgumentError, /:ignore/)
    end

    it "raises ArgumentError when algorithms is explicitly empty" do
      expect do
        build_middleware(on_partial_content: :raise, unencoded_digest: {algorithms: []})
      end.to raise_error(ArgumentError, /algorithms cannot be empty/)
    end

    it "accepts unencoded_digest: true" do
      expect { build_middleware(on_partial_content: :raise, unencoded_digest: true) }
        .not_to raise_error
    end

    it "accepts unencoded_digest: {} (treated as true — uses default algorithms)" do
      expect { build_middleware(on_partial_content: :raise, unencoded_digest: {}) }
        .not_to raise_error
    end

    it "accepts :warn as a valid global on_partial_content value" do
      expect { build_middleware(on_partial_content: :warn, unencoded_digest: true) }
        .not_to raise_error
    end

    it "accepts :skip as a valid global on_partial_content value" do
      expect { build_middleware(on_partial_content: :skip, unencoded_digest: true) }
        .not_to raise_error
    end

    it "accepts a full options hash with per-header override" do
      expect do
        build_middleware(
          on_partial_content: :skip,
          unencoded_digest: {algorithms: %w[sha-256], on_partial_content: :warn}
        )
      end.not_to raise_error
    end
  end
end
