# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "ai-chat"
  spec.version = "0.0.0"
  spec.authors = ["Raghu Betina"]
  spec.email = ["raghu@firstdraft.com"]
  spec.homepage = "https://github.com/firstdraft/ai-chat"
  spec.summary = "A library that makes it as easy as possible to use Chat Completion endpoints in your Ruby application."
  spec.license = "Hippocratic-2.1"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/firstdraft/ai-chat/issues",
    "changelog_uri" => "https://github.com/firstdraft/ai-chat/releases",
    "homepage_uri" => "https://github.com/firstdraft/ai-chat",
    # "funding_uri" => "https://github.com/sponsors/undefined",
    "label" => "AI::Chat",
    # "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/firstdraft/ai-chat"
  }

  # spec.signing_key = Gem.default_key_path
  # spec.cert_chain = [Gem.default_cert_path]

  spec.required_ruby_version = "~> 3.3"
  spec.add_dependency "refinements", "~> 12.10"
  spec.add_dependency "zeitwerk", "~> 2.7"

  spec.extra_rdoc_files = Dir["README*", "LICENSE*"]
  spec.files = Dir["*.gemspec", "lib/**/*"]
end
