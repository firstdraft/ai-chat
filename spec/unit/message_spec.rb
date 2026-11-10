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

    it "truncates base64 data URIs in content" do
      base64_image = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk"
      message = AI::Message[
        role: "user",
        content: [
          {type: "input_text", text: "What is this?"},
          {type: "input_image", image_url: base64_image}
        ]
      ]

      expect(message.inspect).to include("data:image/png;base64,iVBORw0KGgoAAAANSUhE... (60 chars)")
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

  describe "printing an Array of messages with pp" do
    before { allow($stdout).to receive(:tty?).and_return(true) }

    it "keeps each separator between the messages it separates" do
      messages = [
        AI::Message[role: "user", content: "Hello"],
        AI::Message[role: "assistant", content: "Hi!", response: {id: "resp_1"}]
      ]

      expect(PP.pp(messages, +"")).to eq(<<~TEXT)
        [{
               role: "user",
            content: "Hello"
        }, {
                role: "assistant",
             content: "Hi!",
            response: {
                id: "resp_1"
            }
        }]
      TEXT
    end
  end

  describe "#pretty_print" do
    it "writes directly to output to bypass IRB colorization" do
      message = AI::Message[role: "user", content: "Hello"]
      output = StringIO.new
      mock_q = double("PrettyPrint", output: output, flush: nil)

      message.pretty_print(mock_q)

      expect(output.string).to eq(message.inspect)
    end
  end

  describe "color" do
    let(:message) { AI::Message[role: "assistant", content: {carbs: 125}, status: :completed] }

    before do
      require "irb/color_printer"
      allow($stdout).to receive(:tty?).and_return(true)
    end

    it "#inspect has no escape codes, even when $stdout is a terminal" do
      expect(message.inspect).not_to include("\e[")
    end

    it "colors IRB's output when IRB's color is on" do
      allow(IRB::Color).to receive(:colorable?).and_return(true)
      allow(AmazingPrint).to receive(:force_colors).and_return(true) # skip its TERM check
      out = +""
      IRB::ColorPrinter.pp(message, out, 80, colorize: true)

      expect(out).to include("\e[")
    end

    # IRB always passes colorize: true; --nocolorize and a dumb terminal
    # show up as IRB::Color.colorable? returning false.
    it "leaves IRB's output plain when IRB's color is off" do
      allow(IRB::Color).to receive(:colorable?).and_return(false)
      out = +""
      IRB::ColorPrinter.pp(message, out, 80, colorize: true)

      expect(out).not_to include("\e[")
    end

    it "leaves plain pp output plain" do
      expect(PP.pp(message, +"")).not_to include("\e[")
    end
  end
end
