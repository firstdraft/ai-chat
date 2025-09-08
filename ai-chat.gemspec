# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "ai-chat"
  spec.version = "0.2.3"
  spec.authors = ["Raghu Betina"]
  spec.email = ["raghu@firstdraft.com"]
  spec.homepage = "https://github.com/firstdraft/ai-chat"
  spec.summary = "A beginner-friendly Ruby interface for OpenAI's API"
  spec.license = "MIT"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/firstdraft/ai-chat/issues",
    "changelog_uri" => "https://github.com/firstdraft/ai-chat/blob/main/CHANGELOG.md",
    "homepage_uri" => "https://github.com/firstdraft/ai-chat",
    "label" => "AI Chat",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/firstdraft/ai-chat"
  }

  spec.required_ruby_version = "~> 3.2"
  spec.add_runtime_dependency "openai", "~> 0.16"
  spec.add_runtime_dependency "marcel", "~> 1.0"
  spec.add_runtime_dependency "base64", "> 0.1.1"
  spec.add_runtime_dependency "json", "~> 2.0"
  spec.add_runtime_dependency "tty-spinner", "~> 0.9.3"

  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "refinements", "~> 11.1"

  spec.extra_rdoc_files = Dir["README*", "LICENSE*"]
  spec.files = Dir["*.gemspec", "lib/**/*"]
end
