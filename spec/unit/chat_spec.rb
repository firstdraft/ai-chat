# frozen_string_literal: true

require "spec_helper"

RSpec.describe AI::Chat do
  let(:chat) { AI::Chat.new }

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
