require "digest"

module DigestFields
  module_function

  def digest(*, **)
    Digestion.compute(*, **)
  end
end

require_relative "digest_fields/version"
require_relative "digest_fields/digestion"
