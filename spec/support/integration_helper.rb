# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :integration) do
    if ENV["AICHAT_PROXY"]&.downcase == "true"
      if ENV["AICHAT_PROXY_KEY"].to_s.empty?
        skip "Proxy mode is on but AICHAT_PROXY_KEY is not set"
      end
    elsif ENV["OPENAI_API_KEY"].to_s.empty?
      skip "Set OPENAI_API_KEY, or enable proxy mode with AICHAT_PROXY=true and AICHAT_PROXY_KEY"
    end
  end
end
