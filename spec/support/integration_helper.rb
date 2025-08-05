# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :integration) do
    if ENV["OPENAI_API_KEY"].nil?
      skip "Integration tests require OPENAI_API_KEY environment variable"
    end
  end
end
