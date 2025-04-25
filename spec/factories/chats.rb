# frozen_string_literal: true

FactoryBot.define do
  factory :chat, class: AI::Chat do
    api_key { "dummy_token" }

    initialize_with { new(api_key: api_key) }
  end
end
