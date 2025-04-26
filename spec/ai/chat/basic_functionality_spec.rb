# frozen_string_literal: true

require "spec_helper"

RSpec.describe AI::Chat, "basic functionality" do
  let(:chat) { build(:chat) }
  let(:test_system_message) { "You are a helpful assistant." }
  let(:test_user_message) { "Hello, world!" }
  let(:test_assistant_message) { "How can I help you today?" }

  describe "#initialize" do
    it "initializes with a provided API key" do
      chat = AI::Chat.new(api_key: "test_key")
      expect(chat.instance_variable_get(:@api_key)).to eq("test_key")
    end

    it "initializes with an API key from the default environment variable" do
      allow(ENV).to receive(:fetch).with("OPENAI_API_KEY").and_return("env_key")
      chat = AI::Chat.new
      expect(chat.instance_variable_get(:@api_key)).to eq("env_key")
    end

    it "initializes with an API key from a custom environment variable" do
      allow(ENV).to receive(:fetch).with("CUSTOM_API_KEY").and_return("custom_env_key")
      chat = AI::Chat.new(api_key_env_var: "CUSTOM_API_KEY")
      expect(chat.instance_variable_get(:@api_key)).to eq("custom_env_key")
    end

    it "initializes with default values" do
      chat = AI::Chat.new(api_key: "test_key")
      expect(chat.messages).to eq([])
      expect(chat.model).to eq("gpt-4.1-nano")
      expect(chat.schema).to be_nil
      expect(chat.reasoning_effort).to be_nil
    end
  end

  describe "#system" do
    it "adds a system message to messages array" do
      chat.system(test_system_message)
      
      expect(chat.messages.length).to eq(1)
      expect(chat.messages.first[:role]).to eq("system")
      expect(chat.messages.first[:content]).to eq(test_system_message)
    end
  end

  describe "#user" do
    context "with text-only content" do
      it "adds a user message with simple text content" do
        chat.user(test_user_message)
        
        expect(chat.messages.length).to eq(1)
        expect(chat.messages.first[:role]).to eq("user")
        expect(chat.messages.first[:content]).to eq(test_user_message)
      end
    end
  end

  describe "#assistant" do
    it "adds an assistant message to messages array" do
      chat.assistant(test_assistant_message)
      
      expect(chat.messages.length).to eq(1)
      expect(chat.messages.first[:role]).to eq("assistant")
      expect(chat.messages.first[:content]).to eq(test_assistant_message)
    end
  end

  describe "#reasoning_effort=" do
    it "accepts valid reasoning effort values as symbols" do
      [:low, :medium, :high].each do |value|
        chat.reasoning_effort = value
        expect(chat.reasoning_effort).to eq(value)
      end
    end

    it "accepts valid reasoning effort values as strings" do
      ["low", "medium", "high"].each do |value|
        chat.reasoning_effort = value
        expect(chat.reasoning_effort).to eq(value.to_sym)
      end
    end

    it "rejects invalid reasoning effort values" do
      expect { chat.reasoning_effort = :invalid }.to raise_error(ArgumentError)
      expect { chat.reasoning_effort = "invalid" }.to raise_error(ArgumentError)
      expect { chat.reasoning_effort = 123 }.to raise_error(ArgumentError)
    end

    it "allows setting to nil" do
      chat.reasoning_effort = :medium
      expect(chat.reasoning_effort).to eq(:medium)
      
      chat.reasoning_effort = nil
      expect(chat.reasoning_effort).to be_nil
    end
  end

  describe "#inspect" do
    it "returns a string representation with essential attributes" do
      chat.system(test_system_message)
      chat.model = "gpt-4"
      chat.reasoning_effort = :high
      
      inspect_output = chat.inspect
      
      expect(inspect_output).to include("AI::Chat")
      expect(inspect_output).to include(chat.messages.inspect)
      expect(inspect_output).to include("gpt-4")
      expect(inspect_output).to include(":high")
    end
  end
end