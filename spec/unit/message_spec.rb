# frozen_string_literal: true

require "spec_helper"

RSpec.describe AI::Message do
  describe "Hash subclass behavior" do
    it "is a subclass of Hash" do
      expect(AI::Message.new).to be_a(Hash)
    end

    it "can be created with Hash.[] syntax" do
      message = AI::Message[role: "user", content: "Hello"]

      expect(message[:role]).to eq("user")
      expect(message[:content]).to eq("Hello")
    end

    it "supports standard Hash operations" do
      message = AI::Message[role: "user"]
      message[:content] = "Hello"

      expect(message.keys).to contain_exactly(:role, :content)
      expect(message.values).to contain_exactly("user", "Hello")
    end
  end

  describe "#inspect" do
    it "returns a String" do
      message = AI::Message[role: "user", content: "Hello"]

      expect(message.inspect).to be_a(String)
    end

    it "does not return raw Hash representation" do
      message = AI::Message[role: "user", content: "Hello"]

      expect(message.inspect).not_to eq({role: "user", content: "Hello"}.inspect)
    end
  end

  describe "#pretty_inspect" do
    it "returns a String ending with newline" do
      message = AI::Message[role: "user", content: "Hello"]

      expect(message.pretty_inspect).to be_a(String)
      expect(message.pretty_inspect).to end_with("\n")
    end
  end

  describe "#to_html" do
    it "returns a String" do
      message = AI::Message[role: "user", content: "Hello"]

      expect(message.to_html).to be_a(String)
    end
  end

  describe "#pretty_print" do
    it "writes directly to output to bypass IRB colorization" do
      message = AI::Message[role: "user", content: "Hello"]
      output = StringIO.new
      mock_q = double("PrettyPrint", output: output)

      message.pretty_print(mock_q)

      expect(output.string).to eq(message.inspect)
    end
  end
end
