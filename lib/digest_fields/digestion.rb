module DigestFields::Digestion
  module_function

  def compute(body, registry:, algorithms:)
    [algorithms].flatten.map do |key|
      "#{key}=:#{registry.fetch(key).call(body)}:"
    end.join(", ")
  end
end
