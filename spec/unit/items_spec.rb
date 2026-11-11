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

    it "keeps separators in place inside an Array" do
      out = PP.pp([items, items], +"")

      expect(out).to eq("[#{items.inspect}, #{items.inspect}]\n")
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

  describe "color" do
    before do
      require "irb/color_printer"
      allow($stdout).to receive(:tty?).and_return(true)
    end

    it "#inspect has no escape codes, even when $stdout is a terminal" do
      expect(items.inspect).not_to include("\e[")
    end

    it "colors IRB's output when IRB's color is on" do
      allow(IRB::Color).to receive(:colorable?).and_return(true)
      allow(AmazingPrint).to receive(:force_colors).and_return(true) # skip its TERM check
      out = +""
      IRB::ColorPrinter.pp(items, out, 80, colorize: true)

      expect(out).to include("\e[")
    end

    # IRB always passes colorize: true, so its color setting reaches us
    # only through IRB::Color.colorable?, which is false when IRB runs
    # with --nocolorize, when stdout isn't a terminal, or when TERM is
    # unset or "dumb" (what a terminal reports when it can't handle
    # escape codes, like an Emacs shell buffer).
    it "leaves IRB's output plain when IRB's color is off" do
      allow(IRB::Color).to receive(:colorable?).and_return(false)
      out = +""
      IRB::ColorPrinter.pp(items, out, 80, colorize: true)

      expect(out).not_to include("\e[")
    end

    it "leaves plain pp output plain" do
      expect(PP.pp(items, +"")).not_to include("\e[")
    end
  end
end
