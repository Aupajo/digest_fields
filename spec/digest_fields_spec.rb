RSpec.describe DigestFields do
  it "has a version number" do
    expect(DigestFields::VERSION).not_to be nil
  end

  it "exposes an Algorithms registry" do
    expect(DigestFields.algorithms).to be_a(DigestFields::Algorithms)
  end

  describe ".digest" do
    it "digests a body with all registered algorithms by default" do
      expect(DigestFields.digest(%({"hello": "world"}\n)))
        .to eq("sha-256=:RK/0qy18MlBSVnWgjwz6lZEWjP/lF5HF9bvEF8FabDg=:, sha-512=:YMAam51Jz/jOATT6/zvHrLVgOYTGFy1d6GJiOHTohq4yP+pgk4vf2aCsyRZOtw8MjkM7iw7yZ/WkppmM44T3qg==:")
    end

    it "accepts a single algorithm: override" do
      expect(DigestFields.digest(%({"hello": "world"}\n), algorithms: "sha-256"))
        .to eq("sha-256=:RK/0qy18MlBSVnWgjwz6lZEWjP/lF5HF9bvEF8FabDg=:")
    end

    it "accepts an array of algorithms: override" do
      expect(DigestFields.digest(%({"hello": "world"}\n), algorithms: %w[sha-512 sha-256]))
        .to eq("sha-512=:YMAam51Jz/jOATT6/zvHrLVgOYTGFy1d6GJiOHTohq4yP+pgk4vf2aCsyRZOtw8MjkM7iw7yZ/WkppmM44T3qg==:, sha-256=:RK/0qy18MlBSVnWgjwz6lZEWjP/lF5HF9bvEF8FabDg=:")
    end
  end
end
