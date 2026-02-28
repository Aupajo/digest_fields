RSpec.describe DigestFields do
  include described_class

  it "has a version number" do
    expect(DigestFields::VERSION).not_to be nil
  end

  let(:spec_examples) do
    {
      b1: {
        body: %({"hello": "world"}\n),
        sha256: "sha-256=:RK/0qy18MlBSVnWgjwz6lZEWjP/lF5HF9bvEF8FabDg=:",
        sha512: "sha-512=:YMAam51Jz/jOATT6/zvHrLVgOYTGFy1d6GJiOHTohq4yP+pgk4vf2aCsyRZOtw8MjkM7iw7yZ/WkppmM44T3qg==:"
      }
    }
  end

  describe ".digest" do
    it "can hash a body into SHA-256" do
      example = spec_examples[:b1]
      digest_value = digest(example[:body], algorithms: :sha256)
      expect(digest_value).to eq(example[:sha256])
    end

    it "can hash a body into SHA-512" do
      example = spec_examples[:b1]
      digest_value = digest(example[:body], algorithms: :sha512)
      expect(digest_value).to eq(example[:sha512])
    end

    it "can hash multiple algorithms" do
      example = spec_examples[:b1]
      digest_value = digest(example[:body], algorithms: %i[sha256 sha512])
      expect(digest_value).to eq("#{example[:sha256]}, #{example[:sha512]}")
    end

    it "raises an error if algorithm is not supported" do
      expect { DigestFields.digest("body", algorithms: :unknown) }
        .to raise_error(ArgumentError, /unknown/)
    end
  end
end
