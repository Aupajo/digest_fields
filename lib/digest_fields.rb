require "digest"

module DigestFields
  def self.algorithms
    @algorithms ||= Algorithms.new
  end

  def self.digest(body, algorithms: self.algorithms.keys)
    Digestion.compute(body, registry: self.algorithms, algorithms: algorithms)
  end
end

require_relative "digest_fields/version"
require_relative "digest_fields/algorithms"
require_relative "digest_fields/digestion"
