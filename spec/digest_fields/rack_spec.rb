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
end
