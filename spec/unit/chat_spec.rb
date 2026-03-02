# frozen_string_literal: true

require "spec_helper"

RSpec.describe AI::Chat do
  let(:chat) { AI::Chat.new }

  def with_env_var(name, value)
    original = ENV.key?(name) ? ENV[name] : :__undefined__

    if value.nil?
      ENV.delete(name)
    else
      ENV[name] = value
    end

    yield
  ensure
    if original == :__undefined__
      ENV.delete(name)
    else
      ENV[name] = original
    end
  end

  def schema_client_double
    response = double("response", output_text: '{"type":"object","properties":{},"required":[],"additionalProperties":false}')
    responses = double("responses")
    allow(responses).to receive(:create).and_return(response)
    double("client", responses: responses)
  end

  around do |example|
    with_env_var("AICHAT_PROXY", nil) do
      example.run
    end
  end

  describe "proxy defaults" do
    it "defaults proxy to false when AICHAT_PROXY is not set" do
      with_env_var("AICHAT_PROXY", nil) do
        client_double = instance_double(OpenAI::Client)
        expect(OpenAI::Client).to receive(:new).with(api_key: "test-key").and_return(client_double)

        instance = AI::Chat.new(api_key: "test-key")

        expect(instance.proxy).to be(false)
      end
    end

    it "defaults proxy to true when AICHAT_PROXY is exactly true" do
      with_env_var("AICHAT_PROXY", "true") do
        client_double = instance_double(OpenAI::Client)
        expect(OpenAI::Client).to receive(:new).with(
          api_key: "test-key",
          base_url: AI::Chat::BASE_PROXY_URL
        ).and_return(client_double)

        instance = AI::Chat.new(api_key: "test-key")

        expect(instance.proxy).to be(true)
      end
    end

    it "does not enable proxy for non-exact truthy values" do
      with_env_var("AICHAT_PROXY", "TRUE") do
        client_double = instance_double(OpenAI::Client)
        expect(OpenAI::Client).to receive(:new).with(api_key: "test-key").and_return(client_double)

        instance = AI::Chat.new(api_key: "test-key")

        expect(instance.proxy).to be(false)
      end
    end

    it "allows explicit override to false even when env default is true" do
      with_env_var("AICHAT_PROXY", "true") do
        client_double = instance_double(OpenAI::Client)
        allow(OpenAI::Client).to receive(:new).and_return(client_double)

        instance = AI::Chat.new(api_key: "test-key")
        instance.proxy = false

        expect(OpenAI::Client).to have_received(:new).with(api_key: "test-key", base_url: AI::Chat::BASE_PROXY_URL)
        expect(OpenAI::Client).to have_received(:new).with(api_key: "test-key")
        expect(instance.proxy).to be(false)
      end
    end

    it "allows explicit override to true when env default is false" do
      with_env_var("AICHAT_PROXY", nil) do
        client_double = instance_double(OpenAI::Client)
        allow(OpenAI::Client).to receive(:new).and_return(client_double)

        instance = AI::Chat.new(api_key: "test-key")
        instance.proxy = true

        expect(OpenAI::Client).to have_received(:new).with(api_key: "test-key")
        expect(OpenAI::Client).to have_received(:new).with(api_key: "test-key", base_url: AI::Chat::BASE_PROXY_URL)
        expect(instance.proxy).to be(true)
      end
    end
  end

  describe ".generate_schema!" do
    it "uses env proxy default when proxy keyword is omitted" do
      with_env_var("AICHAT_PROXY", "true") do
        client_double = schema_client_double
        expect(OpenAI::Client).to receive(:new).with(
          api_key: "test-key",
          base_url: AI::Chat::BASE_PROXY_URL
        ).and_return(client_double)

        result = AI::Chat.generate_schema!("A tiny schema", api_key: "test-key", location: false)

        expect(result).to include("\"type\": \"object\"")
      end
    end

    it "lets explicit proxy false override env proxy default" do
      with_env_var("AICHAT_PROXY", "true") do
        client_double = schema_client_double
        expect(OpenAI::Client).to receive(:new).with(api_key: "test-key").and_return(client_double)

        AI::Chat.generate_schema!("A tiny schema", api_key: "test-key", location: false, proxy: false)
      end
    end

    it "lets explicit proxy true override env proxy default" do
      with_env_var("AICHAT_PROXY", nil) do
        client_double = schema_client_double
        expect(OpenAI::Client).to receive(:new).with(
          api_key: "test-key",
          base_url: AI::Chat::BASE_PROXY_URL
        ).and_return(client_double)

        AI::Chat.generate_schema!("A tiny schema", api_key: "test-key", location: false, proxy: true)
      end
    end
  end

  describe "#add" do
    it "returns the added message, not the messages array" do
      result = chat.add("Hello", role: "user")

      expect(result).not_to be_an(Array)
      expect(result[:content]).to eq("Hello")
      expect(result[:role]).to eq("user")
    end

    it "returns an AI::Message instance" do
      result = chat.add("Hello", role: "user")

      expect(result).to be_an(AI::Message)
    end

    it "still adds the message to the messages array" do
      chat.add("Hello", role: "user")

      expect(chat.messages.count).to eq(1)
      expect(chat.messages.first[:content]).to eq("Hello")
    end

    it "only includes :response key when response is provided" do
      result_without_response = chat.add("Hello", role: "user")
      result_with_response = chat.add("Hi", role: "assistant", response: {id: "resp_123"})

      expect(result_without_response).not_to have_key(:response)
      expect(result_with_response).to have_key(:response)
      expect(result_with_response[:response]).to eq({id: "resp_123"})
    end

    it "only includes :status key when status is provided" do
      result_without_status = chat.add("Hello", role: "user")
      result_with_status = chat.add("Hi", role: "assistant", status: :completed)

      expect(result_without_status).not_to have_key(:status)
      expect(result_with_status).to have_key(:status)
      expect(result_with_status[:status]).to eq(:completed)
    end

    it "only includes :content key when content is provided" do
      result_with_content = chat.add("Hello", role: "user")
      result_without_content = chat.add(nil, role: "system")

      expect(result_with_content).to have_key(:content)
      expect(result_without_content).not_to have_key(:content)
    end
  end

  describe "#system" do
    it "returns an AI::Message" do
      result = chat.system("You are helpful")

      expect(result).to be_an(AI::Message)
      expect(result[:role]).to eq("system")
    end
  end

  describe "#user" do
    it "returns an AI::Message" do
      result = chat.user("Hello")

      expect(result).to be_an(AI::Message)
      expect(result[:role]).to eq("user")
    end
  end

  describe "#assistant" do
    it "returns an AI::Message" do
      result = chat.assistant("Hello!")

      expect(result).to be_an(AI::Message)
      expect(result[:role]).to eq("assistant")
    end
  end

  describe "#inspectable_attributes" do
    it "excludes :response key from displayed messages" do
      chat.add("Hello", role: "user")
      chat.add("Hi there!", role: "assistant", response: {id: "resp_123", model: "gpt-4"})

      attrs = chat.inspectable_attributes
      messages_attr = attrs.find { |name, _| name == :@messages }
      display_messages = messages_attr[1]

      display_messages.each do |msg|
        expect(msg).not_to have_key(:response)
      end
    end

    it "includes @last_response_id only when set" do
      attrs_without = chat.inspectable_attributes
      attr_names_without = attrs_without.map(&:first)

      expect(attr_names_without).not_to include(:@last_response_id)

      chat.instance_variable_set(:@last_response_id, "resp_123")
      attrs_with = chat.inspectable_attributes

      last_response_attr = attrs_with.find { |name, _| name == :@last_response_id }
      expect(last_response_attr).not_to be_nil
      expect(last_response_attr[1]).to eq("resp_123")
    end

    it "shows @last_response_id after @conversation_id" do
      chat.instance_variable_set(:@conversation_id, "conv_123")
      chat.instance_variable_set(:@last_response_id, "resp_456")

      attrs = chat.inspectable_attributes
      attr_names = attrs.map(&:first)

      conv_index = attr_names.index(:@conversation_id)
      resp_index = attr_names.index(:@last_response_id)

      expect(resp_index).to eq(conv_index + 1)
    end

    it "excludes optional features when at default values" do
      attrs = chat.inspectable_attributes
      attr_names = attrs.map(&:first)

      expect(attr_names).not_to include(:@proxy)
      expect(attr_names).not_to include(:@image_generation)
      expect(attr_names).not_to include(:@image_folder)
    end

    it "includes optional features when changed from defaults" do
      chat.proxy = true
      chat.image_generation = true
      chat.image_folder = "./my_images"

      attrs = chat.inspectable_attributes
      attr_names = attrs.map(&:first)

      expect(attr_names).to include(:@proxy)
      expect(attr_names).to include(:@image_generation)
      expect(attr_names).to include(:@image_folder)
    end

    it "excludes optional state when not set" do
      attrs = chat.inspectable_attributes
      attr_names = attrs.map(&:first)

      expect(attr_names).not_to include(:@background)
      expect(attr_names).not_to include(:@code_interpreter)
      expect(attr_names).not_to include(:@web_search)
      expect(attr_names).not_to include(:@schema)
    end

    it "includes optional state when set" do
      chat.background = true
      chat.code_interpreter = true
      chat.web_search = true
      chat.schema = {name: "test", strict: true, schema: {type: "object", properties: {}, additionalProperties: false}}

      attrs = chat.inspectable_attributes
      attr_names = attrs.map(&:first)

      expect(attr_names).to include(:@background)
      expect(attr_names).to include(:@code_interpreter)
      expect(attr_names).to include(:@web_search)
      expect(attr_names).to include(:@schema)
    end

    it "truncates base64 data URIs in message content" do
      base64_image = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk"
      chat.add([
        {type: "input_text", text: "What is this?"},
        {type: "input_image", image_url: base64_image}
      ], role: "user")

      attrs = chat.inspectable_attributes
      messages_attr = attrs.find { |name, _| name == :@messages }
      display_messages = messages_attr[1]
      image_content = display_messages[0][:content][1]

      expect(image_content[:image_url]).to eq("data:image/png;base64,iVBORw0KGgoAAAANSUhE... (60 chars)")
    end

    it "does not truncate regular strings" do
      chat.add("Hello, this is a normal message", role: "user")

      attrs = chat.inspectable_attributes
      messages_attr = attrs.find { |name, _| name == :@messages }
      display_messages = messages_attr[1]

      expect(display_messages[0][:content]).to eq("Hello, this is a normal message")
    end

    it "does not truncate non-base64 data URIs" do
      data_uri = "data:text/plain,Hello%20World"
      chat.add([{type: "input_text", text: data_uri}], role: "user")

      attrs = chat.inspectable_attributes
      messages_attr = attrs.find { |name, _| name == :@messages }
      display_messages = messages_attr[1]

      expect(display_messages[0][:content][0][:text]).to eq(data_uri)
    end
  end

  describe "#inspect" do
    it "returns a String" do
      expect(chat.inspect).to be_a(String)
    end
  end

  describe "#pretty_inspect" do
    it "returns a String ending with newline" do
      expect(chat.pretty_inspect).to be_a(String)
      expect(chat.pretty_inspect).to end_with("\n")
    end
  end

  describe "#to_html" do
    it "returns a String" do
      expect(chat.to_html).to be_a(String)
    end
  end
end
