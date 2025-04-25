# frozen_string_literal: true

FactoryBot.define do
  factory :chat, class: AI::Chat do
    api_token { "dummy_token" }
    provider { :openai }

    initialize_with { new(api_token: api_token, provider: provider) }

    trait :openai do
      provider { :openai }
    end

    trait :gemini do
      provider { :gemini }
    end

    trait :anthropic do
      provider { :anthropic }
    end
  end
end
