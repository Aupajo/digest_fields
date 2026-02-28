module DigestFields::Digestion
  ALGORITHMS = {
    sha256: ->(body) { Digest::SHA256.base64digest(body) },
    sha512: ->(body) { Digest::SHA512.base64digest(body) }
  }

  module_function

  def compute(body, algorithms: %i[sha256 sha512])
    algorithms = [algorithms].flatten

    algorithms.map do |algorithm|
      key = algorithm.to_s.sub(/(\d+)$/, '-\1')

      algorithm = ALGORITHMS.fetch(algorithm) do
        raise ArgumentError, "#{algorithm.inspect} not available (try one of: #{ALGORITHMS.keys.join(", ")})"
      end

      digest = algorithm.call(body)

      "#{key}=:#{digest}:"
    end.join(", ")
  end
end
