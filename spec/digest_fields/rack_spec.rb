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

    it "raises ArgumentError when unencoded_digest is not true or a Hash" do
      expect { build_middleware(on_partial_content: :raise, unencoded_digest: false) }
        .to raise_error(ArgumentError, /unencoded_digest must be true or a Hash/)
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

  describe "#call — 200 response" do
    let(:middleware) { build_middleware(on_partial_content: :raise, unencoded_digest: true) }

    it "adds Unencoded-Digest with both default algorithms" do
      _status, headers, _body = middleware.call({})
      expect(headers["Unencoded-Digest"])
        .to eq("sha-256=:#{sha256_value}:, sha-512=:#{sha512_value}:")
    end

    it "returns the original status code" do
      status, _headers, _body = middleware.call({})
      expect(status).to eq(200)
    end

    it "returns the buffered body as a single-element array" do
      _status, _headers, body = middleware.call({})
      expect(body).to eq([body_string])
    end

    context "with a custom algorithm" do
      let(:middleware) do
        build_middleware(on_partial_content: :raise, unencoded_digest: {algorithms: %w[sha-256]})
      end

      it "includes only the specified algorithm" do
        _status, headers, _body = middleware.call({})
        expect(headers["Unencoded-Digest"]).to eq("sha-256=:#{sha256_value}:")
      end
    end

    context "when a downstream middleware would apply content-encoding (e.g. Rack::Deflater)" do
      # The middleware sees the raw bytes before any encoding is applied.
      # This confirms Unencoded-Digest is computed over the unencoded body regardless
      # of what happens downstream — as long as the middleware is positioned before
      # any encoding middleware.
      it "computes the digest over the unencoded body bytes" do
        # Same fixture body, same expected digest — positioning before Rack::Deflater
        # means the middleware sees and digests the unencoded string.
        _status, headers, _body = middleware.call({})
        expect(headers["Unencoded-Digest"]).to include("sha-256=:#{sha256_value}:")
      end
    end

    context "with a multi-chunk body" do
      let(:chunks) { ["An unexceptional ", "string\n"] }
      let(:middleware) do
        build_middleware(
          stub_app(body: chunks),
          on_partial_content: :raise,
          unencoded_digest: {algorithms: %w[sha-256]}
        )
      end

      it "joins chunks before digesting" do
        _status, headers, _body = middleware.call({})
        expect(headers["Unencoded-Digest"]).to eq("sha-256=:#{sha256_value}:")
      end

      it "returns the joined body" do
        _status, _headers, body = middleware.call({})
        expect(body).to eq([body_string])
      end
    end
  end

  describe "#call — body.close" do
    it "calls close on the original body after buffering" do
      closeable_body = ["An unexceptional string\n"]
      closed = false
      closeable_body.define_singleton_method(:close) { closed = true }

      middleware = build_middleware(
        stub_app(body: closeable_body),
        on_partial_content: :raise,
        unencoded_digest: {algorithms: %w[sha-256]}
      )
      middleware.call({})

      expect(closed).to be(true)
    end

    it "does not call close on bodies that do not respond to close" do
      plain_body = ["An unexceptional string\n"]
      middleware = build_middleware(
        stub_app(body: plain_body),
        on_partial_content: :raise,
        unencoded_digest: {algorithms: %w[sha-256]}
      )
      status, headers, _body = middleware.call({})
      expect(status).to eq(200)
      expect(headers).to have_key("Unencoded-Digest")
    end
  end

  describe "#call — 206 Partial Content" do
    let(:partial_app) { stub_app(status: 206) }

    context "with on_partial_content: :raise" do
      let(:middleware) { build_middleware(partial_app, on_partial_content: :raise, unencoded_digest: true) }

      it "raises PartialContentError" do
        expect { middleware.call({}) }
          .to raise_error(Rack::DigestFields::PartialContentError)
      end
    end

    context "with on_partial_content: :skip" do
      let(:original_body) { ["An unexceptional string\n"] }
      let(:middleware) { build_middleware(stub_app(status: 206, body: original_body), on_partial_content: :skip, unencoded_digest: true) }

      it "omits the Unencoded-Digest header" do
        _status, headers, _body = middleware.call({})
        expect(headers).not_to have_key("Unencoded-Digest")
      end

      it "returns the original body object unchanged" do
        _status, _headers, body = middleware.call({})
        expect(body).to be(original_body)
      end

      it "does not call close on the body" do
        closed = false
        original_body.define_singleton_method(:close) { closed = true }
        middleware.call({})
        expect(closed).to be(false)
      end
    end

    context "with on_partial_content: :warn" do
      let(:original_body) { ["An unexceptional string\n"] }
      let(:middleware) { build_middleware(stub_app(status: 206, body: original_body), on_partial_content: :warn, unencoded_digest: true) }

      it "omits the Unencoded-Digest header" do
        _status, headers, _body = middleware.call({})
        expect(headers).not_to have_key("Unencoded-Digest")
      end

      it "emits a warning" do
        expect { middleware.call({}) }
          .to output(/Unencoded-Digest/).to_stderr
      end

      it "does not call close on the body" do
        closed = false
        original_body.define_singleton_method(:close) { closed = true }
        middleware.call({})
        expect(closed).to be(false)
      end
    end

    context "with per-header on_partial_content overriding global" do
      let(:middleware) do
        build_middleware(
          partial_app,
          on_partial_content: :skip,
          unencoded_digest: {algorithms: %w[sha-256], on_partial_content: :warn}
        )
      end

      it "uses the per-header setting (warn) rather than the global (skip)" do
        expect { middleware.call({}) }
          .to output(/Unencoded-Digest/).to_stderr
      end
    end
  end
end
