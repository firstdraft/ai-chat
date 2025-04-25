# frozen_string_literal: true

require "spec_helper"

RSpec.describe AI::Chat, "providers" do
  describe "initialization" do
    it "defaults to OpenAI provider" do
      chat = AI::Chat.new(api_token: "dummy_token")
      expect(chat.provider).to eq(:openai)
      expect(chat.model).to eq("gpt-4o")
    end

    it "allows setting a different provider" do
      chat = AI::Chat.new(api_token: "dummy_token", provider: :gemini)
      expect(chat.provider).to eq(:gemini)
      expect(chat.model).to eq("gemini-1.5-pro")
    end

    it "allows setting a custom model" do
      chat = AI::Chat.new(api_token: "dummy_token", provider: :anthropic, model: "claude-3-5-sonnet")
      expect(chat.provider).to eq(:anthropic)
      expect(chat.model).to eq("claude-3-5-sonnet")
    end

    it "finds API token from appropriate environment variables" do
      # Temporarily set environment variables
      original_env = ENV.to_hash

      begin
        ENV.clear
        ENV["GEMINI_TOKEN"] = "gemini_token_value"

        chat = AI::Chat.new(provider: :gemini)
        expect(chat.instance_variable_get(:@api_token)).to eq("gemini_token_value")
      ensure
        # Restore original environment
        ENV.clear
        original_env.each { |k, v| ENV[k] = v }
      end
    end
  end

  describe "API requests", :vcr do
    let(:openai_chat) { build(:chat, :openai) }
    let(:gemini_chat) { build(:chat, :gemini) }
    let(:anthropic_chat) { build(:chat, :anthropic) }

    # Note: These tests will use VCR cassettes to mock the API responses

    describe "OpenAI provider" do
      it "makes a request to the OpenAI API endpoint" do
        # Use webmock to stub the request
        stub_request(:post, AI::Chat::PROVIDERS[:openai][:api_endpoint])
          .to_return(
            status: 200,
            body: {
              "choices" => [
                {
                  "message" => {
                    "content" => "This is a test response from OpenAI"
                  }
                }
              ]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        openai_chat.system("You are a helpful assistant")
        openai_chat.user("Hello")
        response = openai_chat.assistant!

        expect(response).to eq("This is a test response from OpenAI")
      end
    end

    describe "Gemini provider" do
      it "makes a request to the Gemini API endpoint" do
        model_name = gemini_chat.model

        # Use webmock to stub the request
        stub_request(:post, "#{AI::Chat::PROVIDERS[:gemini][:api_endpoint]}/#{model_name}:generateContent")
          .to_return(
            status: 200,
            body: {
              "candidates" => [
                {
                  "content" => {
                    "parts" => [
                      {"text" => "This is a test response from Gemini"}
                    ]
                  }
                }
              ]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        gemini_chat.user("Hello")
        response = gemini_chat.assistant!

        expect(response).to eq("This is a test response from Gemini")
      end
    end

    describe "Anthropic provider" do
      it "makes a request to the Anthropic API endpoint" do
        # Use webmock to stub the request
        stub_request(:post, AI::Chat::PROVIDERS[:anthropic][:api_endpoint])
          .to_return(
            status: 200,
            body: {
              "content" => [
                {"type" => "text", "text" => "This is a test response from Anthropic"}
              ]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        anthropic_chat.system("You are a helpful assistant")
        anthropic_chat.user("Hello")
        response = anthropic_chat.assistant!

        expect(response).to eq("This is a test response from Anthropic")
      end
    end
  end
end
