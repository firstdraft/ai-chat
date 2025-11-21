# frozen_string_literal: true

require "spec_helper"

RSpec.describe "AI::Chat Integration", :integration do
  describe "basic chat functionality" do
    it "generates a response to a simple question" do
      chat = AI::Chat.new
      chat.user("What is 2 + 2?")

      response = chat.generate!

      expect(response).to be_a(String)
      expect(response).to match(/4|four/i)
      expect(chat.messages.count).to eq(2)
      expect(chat.messages.last[:role]).to eq("assistant")
      expect(chat.messages.last[:response]).to be_a(Hash)
    end

    it "maintains conversation context across multiple turns" do
      chat = AI::Chat.new
      chat.user("My favorite color is purple.")
      chat.generate!

      chat.user("What is my favorite color?")
      response = chat.generate!

      expect(response).to match(/purple/i)
      expect(chat.messages.count).to eq(4)
    end
  end

  describe "message types" do
    it "supports convenience methods for adding messages" do
      chat = AI::Chat.new

      chat.system("You are helpful")
      chat.user("Hi")
      chat.assistant("Hello!")

      expect(chat.messages[0][:role]).to eq("system")
      expect(chat.messages[1][:role]).to eq("user")
      expect(chat.messages[2][:role]).to eq("assistant")
    end

    it "supports the add method with role parameter" do
      chat = AI::Chat.new

      chat.add("You are helpful", role: "system")
      chat.add("Hi")  # defaults to user
      chat.add("Hello!", role: "assistant")

      expect(chat.messages[0][:role]).to eq("system")
      expect(chat.messages[1][:role]).to eq("user")
      expect(chat.messages[2][:role]).to eq("assistant")
    end
  end

  describe "structured output" do
    it "returns parsed JSON when schema is set" do
      chat = AI::Chat.new
      chat.system("Extract the color and animal from the user's message.")

      schema = {
        name: "extraction",
        strict: true,
        schema: {
          type: "object",
          properties: {
            color: {type: "string", description: "The color mentioned"},
            animal: {type: "string", description: "The animal mentioned"}
          },
          required: ["color", "animal"],
          additionalProperties: false
        }
      }

      chat.schema = schema
      chat.user("I saw a red fox today")

      response = chat.generate!

      expect(response).to be_a(Hash)
      expect(response[:color]).to eq("red")
      expect(response[:animal]).to eq("fox")
    end

    it "accepts schema as a JSON string" do
      chat = AI::Chat.new
      chat.system("Return a number between 1 and 10")

      schema_json = '{"name": "number", "strict": true, "schema": {"type": "object", "properties": {"value": {"type": "integer"}}, "required": ["value"], "additionalProperties": false}}'

      chat.schema = schema_json
      chat.user("Give me a random number")

      response = chat.generate!

      expect(response).to be_a(Hash)
      expect(response[:value]).to be_a(Integer)
      expect(response[:value]).to be_between(1, 10)
    end
  end

  describe "previous_response_id functionality" do
    it "continues a conversation using previous_response_id" do
      # First conversation
      chat1 = AI::Chat.new
      chat1.user("My name is Alice and I live in Boston.")
      chat1.generate!

      response_id = chat1.previous_response_id
      expect(response_id).to match(/^resp_/)

      # New conversation continuing from previous
      chat2 = AI::Chat.new
      chat2.previous_response_id = response_id
      chat2.user("What is my name and where do I live?")

      response = chat2.generate!

      expect(response).to match(/Alice/i)
      expect(response).to match(/Boston/i)
    end

    it "automatically updates previous_response_id after each generate!" do
      chat = AI::Chat.new

      expect(chat.previous_response_id).to be_nil

      chat.user("Hello")
      chat.generate!

      first_id = chat.previous_response_id
      expect(first_id).to match(/^resp_/)

      chat.user("Goodbye")
      chat.generate!

      second_id = chat.previous_response_id
      expect(second_id).to match(/^resp_/)
      expect(second_id).not_to eq(first_id)
    end
  end

  describe "model selection" do
    it "uses gpt-4.1-nano by default" do
      chat = AI::Chat.new
      expect(chat.model).to eq("gpt-4.1-nano")

      chat.user("Hi")
      chat.generate!

      expect(chat.last[:response].model).to match(/gpt-4/)
    end

    it "allows setting a different model" do
      chat = AI::Chat.new
      chat.model = "gpt-4o-mini"

      chat.user("Hi")
      chat.generate!

      expect(chat.last[:response].model).to match(/gpt-4o-mini/)
    end
  end

  describe "web search functionality" do
    it "can use web search when enabled" do
      chat = AI::Chat.new
      chat.model = "gpt-4o-mini"  # Use a model that supports web search
      chat.web_search = true

      chat.user("What is the current price of Bitcoin in USD? Please search for the latest information.")
      response = chat.generate!

      expect(response).to be_a(String)
      expect(response).to match(/\$|USD|dollar/i)
    end
  end

  describe "image handling" do
    context "with a test image URL" do
      let(:test_image_url) { "https://picsum.photos/200/300" }

      it "accepts image URLs" do
        chat = AI::Chat.new
        chat.user("What do you see in this image?", image: test_image_url)

        response = chat.generate!

        expect(response).to be_a(String)
        expect(response.length).to be > 10
      end

      it "accepts multiple images" do
        chat = AI::Chat.new
        chat.user("Compare these images", images: [test_image_url, test_image_url])

        response = chat.generate!

        expect(response).to be_a(String)
        expect(response.length).to be > 10
      end
    end
  end

  describe "API key configuration" do
    it "uses OPENAI_API_KEY environment variable by default" do
      expect { AI::Chat.new }.not_to raise_error
    end

    it "accepts a custom environment variable name" do
      ENV["CUSTOM_OPENAI_KEY"] = ENV["OPENAI_API_KEY"]

      chat = AI::Chat.new(api_key_env_var: "CUSTOM_OPENAI_KEY")
      chat.user("Hi")

      expect { chat.generate! }.not_to raise_error
    ensure
      ENV.delete("CUSTOM_OPENAI_KEY")
    end

    it "accepts an API key directly" do
      chat = AI::Chat.new(api_key: ENV["OPENAI_API_KEY"])
      chat.user("Hi")

      expect { chat.generate! }.not_to raise_error
    end
  end

  describe "response details" do
    it "stores response metadata" do
      chat = AI::Chat.new
      chat.user("Hello!")
      chat.generate!

      response_obj = chat.last[:response]

      expect(response_obj).to be_a(Hash)
      expect(response_obj[:id]).to match(/^resp_/)
      expect(response_obj[:model]).to be_a(String)
      expect(response_obj[:usage]).to be_a(Hash)
      expect(response_obj[:usage][:total_tokens]).to be_a(Integer)
      expect(response_obj[:total_tokens]).to eq(response_obj[:usage][:total_tokens])
    end
  end

  describe "messages manipulation" do
    it "allows setting messages directly" do
      chat = AI::Chat.new

      chat.messages = [
        {role: "system", content: "You are helpful"},
        {role: "user", content: "Hi"},
        {role: "assistant", content: "Hello!"}
      ]

      expect(chat.messages.count).to eq(3)

      chat.user("How are you?")
      response = chat.generate!

      expect(response).to be_a(String)
      expect(chat.messages.count).to eq(5)
    end

    it "provides last as a convenience method" do
      chat = AI::Chat.new
      chat.user("Hello")
      chat.generate!

      expect(chat.last).to eq(chat.messages.last)
      expect(chat.last[:role]).to eq("assistant")
    end
  end
end
