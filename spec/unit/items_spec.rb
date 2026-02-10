# frozen_string_literal: true

require "spec_helper"
require "pp"

RSpec.describe AI::Items do
  let(:sample_data) do
    [
      {type: :message, role: "user", content: [{type: "input_text", text: "Hello"}]},
      {type: :message, role: "assistant", content: [{type: "output_text", text: "Hi there!"}]}
    ]
  end
  let(:response) { OpenStruct.new(data: sample_data, has_more: false, first_id: "item_1", last_id: "item_2") }
  let(:conversation_id) { "conv_abc123" }
  let(:items) { AI::Items.new(response, conversation_id: conversation_id) }

  describe "delegation" do
    it "delegates #data to the underlying response" do
      expect(items.data).to eq(sample_data)
    end

    it "delegates pagination fields to the underlying response" do
      expect(items.has_more).to eq(false)
      expect(items.first_id).to eq("item_1")
      expect(items.last_id).to eq("item_2")
    end

    it "allows iterating over data" do
      results = []
      items.data.each { |item| results << item[:type] }
      expect(results).to eq([:message, :message])
    end
  end

  describe "#inspect" do
    it "returns a String" do
      expect(items.inspect).to be_a(String)
    end

    it "includes conversation_id in the output" do
      expect(items.inspect).to include("conv_abc123")
    end

    it "includes item count in the output" do
      expect(items.inspect).to include("Items: 2")
    end
  end

  describe "#pretty_inspect" do
    it "returns a String ending with newline" do
      expect(items.pretty_inspect).to be_a(String)
      expect(items.pretty_inspect).to end_with("\n")
    end
  end

  describe "#pretty_print" do
    it "is used by PP/IRB and outputs the custom formatted view" do
      out = +""
      PP.pp(items, out)

      expect(out).to include("Conversation: conv_abc123")
      expect(out).to include("Items: 2")
    end
  end

  describe "#to_html" do
    it "returns a String" do
      expect(items.to_html).to be_a(String)
    end

    it "includes conversation_id in the output" do
      expect(items.to_html).to include("conv_abc123")
    end

    it "includes the dark background style" do
      expect(items.to_html).to include("background-color: #1e1e1e")
    end
  end
end
