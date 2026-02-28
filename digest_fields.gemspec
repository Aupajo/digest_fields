require_relative "lib/digest_fields/version"

Gem::Specification.new do |spec|
  spec.name = "digest_fields"
  spec.version = DigestFields::VERSION
  spec.authors = ["Pete Nicholls"]
  spec.email = ["aupajo@gmail.com"]

  spec.summary = "Content-Digest header support following Digest Fields spec (RFC 9530)"
  spec.homepage = "https://github.com/aupajo/digest_fields"
  spec.license = "MIT"
  spec.cert_chain = ["certs/aupajo.pem"]

  # Only require signing key when running the `gem` command (e.g. during release), not during development
  if $0.end_with?("gem")
    require "openssl"
    vault = "tio43q55o6ni477lfck3jurmeq"
    item = "doyymoixsxbqlogxqcuyzzhetq"
    raw_key = `op read "op://#{vault}/#{item}/RubyGems 2026 Private Key.pem"`.chomp
    password = `op read "op://#{vault}/#{item}/password"`.chomp
    spec.signing_key = OpenSSL::PKey.read(raw_key, password)
  end

  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aupajo/digest_fields"
  spec.metadata["changelog_uri"] = "https://github.com/aupajo/digest_fields"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.each_line("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
