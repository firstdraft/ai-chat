# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :quality do
  gem "reek", "~> 6.5", require: false
  gem "simplecov", "~> 0.22", require: false
  gem "standard", "~> 1.53", require: false
end

group :development do
  gem "rake", "~> 13.3"
end

group :test do
  gem "rspec", "~> 3.13"
  gem "ostruct", "~> 0.6"
end

group :tools do
  gem "amazing_print", "~> 2.0"
  gem "debug", "~> 1.11"
  gem "repl_type_completor", "~> 0.1"
end
