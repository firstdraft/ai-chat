# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :integration) do
    if ENV["AICHAT_API_KEY"].to_s.empty? && ENV["OPENAI_API_KEY"].to_s.empty?
      skip "Integration tests require AICHAT_API_KEY or OPENAI_API_KEY environment variable"
    end
  end
end
