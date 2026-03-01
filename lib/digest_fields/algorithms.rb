module DigestFields
  class Algorithms
    def initialize
      reset!
    end

    def add(key, callable)
      @registry[key] = callable
    end

    def reset!
      @registry = {}
      add("sha-256", ->(body) { Digest::SHA256.base64digest(body) })
      add("sha-512", ->(body) { Digest::SHA512.base64digest(body) })
    end

    def keys
      @registry.keys
    end

    def fetch(key)
      @registry.fetch(key) do
        raise ArgumentError, "#{key.inspect} not available (try one of: #{@registry.keys.join(", ")})"
      end
    end
  end
end
