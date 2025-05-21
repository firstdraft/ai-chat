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

  describe "#add" do
    context "when adding a system message" do
      it "adds a system message to messages array" do
        chat.add(test_system_message, role: "system")

        expect(chat.messages.length).to eq(1)
        expect(chat.messages.first[:role]).to eq("system")
        expect(chat.messages.first[:content]).to eq(test_system_message)
      end
    end

    context "when adding a user message" do
      it "adds a user message with simple text content" do
        chat.add(test_user_message, role: "user")

        expect(chat.messages.length).to eq(1)
        expect(chat.messages.first[:role]).to eq("user")
        expect(chat.messages.first[:content]).to eq(test_user_message)
      end

      # Basic test for image handling with #add; more detailed tests are in image_handling_spec.rb
      it "adds a user message with text and an image" do
        allow(chat).to receive(:process_image).with("image.jpg").and_return("processed_image_data")
        chat.add("User message with image", role: "user", image: "image.jpg")

        expect(chat.messages.length).to eq(1)
        expect(chat.messages.first[:role]).to eq("user")
        expect(chat.messages.first[:content]).to be_an(Array)
        expect(chat.messages.first[:content]).to include({type: "text", text: "User message with image"})
        expect(chat.messages.first[:content]).to include({type: "image_url", image_url: {url: "processed_image_data"}})
      end
    end

    context "when adding an assistant message" do
      it "adds an assistant message to messages array" do
        chat.add(test_assistant_message, role: "assistant")

        expect(chat.messages.length).to eq(1)
        expect(chat.messages.first[:role]).to eq("assistant")
        expect(chat.messages.first[:content]).to eq(test_assistant_message)
      end
    end
  end

  describe "deprecated methods" do
    describe "#system (deprecated)" do
      it "adds a system message and prints a deprecation warning" do
        expect { chat.system(test_system_message) }.to output(
          "The `system` method is deprecated. Use `add(content, role: \"system\")` instead.\n"
        ).to_stderr

        expect(chat.messages.length).to eq(1)
        expect(chat.messages.first[:role]).to eq("system")
        expect(chat.messages.first[:content]).to eq(test_system_message)
      end
    end

    describe "#user (deprecated)" do
      context "with text-only content" do
        it "adds a user message and prints a deprecation warning" do
          expect { chat.user(test_user_message) }.to output(
            "The `user` method is deprecated. Use `add(content, role: \"user\", image: image, images: images)` instead.\n"
          ).to_stderr

          expect(chat.messages.length).to eq(1)
          expect(chat.messages.first[:role]).to eq("user")
          expect(chat.messages.first[:content]).to eq(test_user_message)
        end
      end

      context "with image content" do
        let(:image_path) { "path/to/image.jpg" }
        let(:processed_image_data) { "data:image/jpeg;base64,processed_data" }

        before do
          allow(chat).to receive(:process_image).with(image_path).and_return(processed_image_data)
        end

        it "adds a user message with an image and prints a deprecation warning" do
          expect { chat.user(test_user_message, image: image_path) }.to output(
            "The `user` method is deprecated. Use `add(content, role: \"user\", image: image, images: images)` instead.\n"
          ).to_stderr

          expect(chat.messages.length).to eq(1)
          expect(chat.messages.first[:role]).to eq("user")
          expect(chat.messages.first[:content]).to be_an(Array)
          expect(chat.messages.first[:content].first[:type]).to eq("text")
          expect(chat.messages.first[:content].first[:text]).to eq(test_user_message)
          expect(chat.messages.first[:content].last[:type]).to eq("image_url")
          expect(chat.messages.first[:content].last[:image_url][:url]).to eq(processed_image_data)
        end
      end
    end

    describe "#assistant (deprecated)" do
      it "adds an assistant message and prints a deprecation warning" do
        expect { chat.assistant(test_assistant_message) }.to output(
          "The `assistant` method is deprecated. Use `add(content, role: \"assistant\")` instead.\n"
        ).to_stderr

        expect(chat.messages.length).to eq(1)
        expect(chat.messages.first[:role]).to eq("assistant")
        expect(chat.messages.first[:content]).to eq(test_assistant_message)
      end
    end

    describe "#assistant! (deprecated)" do
      before do
        # Stub the actual API call within generate! to avoid external HTTP requests
        allow(chat).to receive(:generate!).and_call_original # So we can check if it was called
        allow(Net::HTTP).to receive(:start).and_return(
          instance_double(Net::HTTPResponse, code: "200", body: {
            "output" => [{
              "type" => "message",
              "content" => [{"type" => "output_text", "text" => "Generated response"}]
            }]
          }.to_json, message: "OK")
        )
      end

      it "calls generate! and prints a deprecation warning" do
        expect(chat).to receive(:generate!).and_call_original
        expect { chat.assistant! }.to output(
          "The `assistant!` method is deprecated. Use `generate!` instead.\n"
        ).to_stderr
        # Verify that a message was added by generate!
        expect(chat.messages.last[:role]).to eq("assistant")
        expect(chat.messages.last[:content]).to eq("Generated response")
      end
    end
  end

  describe "#generate!" do
    # Minimal test for generate! as its core functionality is tested by the deprecated assistant! tests for now
    # and more detailed generation tests are likely in other spec files.
    before do
      allow(Net::HTTP).to receive(:start).and_return(
        instance_double(Net::HTTPResponse, code: "200", body: {
          "output" => [{
            "type" => "message",
            "content" => [{"type" => "output_text", "text" => "Generated response from generate!"}]
          }]
        }.to_json, message: "OK")
      )
    end

    it "makes an API call and adds an assistant message" do
      chat.add("Prompt for generate!", role: "user")
      chat.generate!
      expect(chat.messages.last[:role]).to eq("assistant")
      expect(chat.messages.last[:content]).to eq("Generated response from generate!")
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
