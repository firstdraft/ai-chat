# frozen_string_literal: true

require_relative "lib/ai/chat/version"

Gem::Specification.new do |spec|
  spec.name = "ai-chat"
  spec.version = AI::Chat::VERSION
  spec.authors = ["Raghu Betina", "Jelani Woods"]
  spec.email = ["raghu@firstdraft.com", "jelani@firstdraft.com"]

  spec.summary = "This gem provides a class called `AI::Chat` that is intended to make it as easy as possible to use OpenAI's Responses API."
  spec.description = "This gem provides a class called `AI::Chat` that is intended to make it as easy as possible to use OpenAI's Responses API. Supports Structured Output and Image Processing."
  spec.homepage = "https://github.com/firstdraft/ai-chat"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.0.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/firstdraft/ai-chat"
  spec.metadata["changelog_uri"] = "https://github.com/firstdraft/ai-chat/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Register dependencies of the gem
  spec.add_runtime_dependency "mime-types", "~> 3.0"
  spec.add_runtime_dependency "base64"  # Works for all Ruby versions

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "factory_bot", "~> 6.2"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "vcr", "~> 6.1"
  spec.add_development_dependency "standard", "~> 1.32"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
