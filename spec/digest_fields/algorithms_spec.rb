RSpec.describe DigestFields::Algorithms do
  subject(:algorithms) { described_class.new }

  describe "#add" do
    it "registers a custom algorithm" do
      algorithms.add("md5", ->(body) { Digest::MD5.base64digest(body) })
      expect(algorithms.keys).to include("md5")
    end
  end

  describe "#reset!" do
    it "restores sha-256 and sha-512 defaults" do
      algorithms.add("md5", ->(body) { Digest::MD5.base64digest(body) })
      algorithms.reset!
      expect(algorithms.keys).to eq(%w[sha-256 sha-512])
    end
  end

  describe "#fetch" do
    it "returns the callable for a registered algorithm" do
      callable = algorithms.fetch("sha-256")
      expect(callable.call(%({"hello": "world"}\n)))
        .to eq("RK/0qy18MlBSVnWgjwz6lZEWjP/lF5HF9bvEF8FabDg=")
    end

    it "raises ArgumentError for an unknown algorithm" do
      expect { algorithms.fetch("unknown") }
        .to raise_error(ArgumentError, /unknown/)
    end
  end
end
