# frozen_string_literal: true

require "spec_helper"

RSpec.describe AI::Chat, "actiontext support" do
  let(:chat) { build(:chat) }
  let(:test_image_path) { File.join(File.dirname(__FILE__), "../../fixtures/test1.jpg") }
  let(:test_image_url) { "https://example.com/image.jpg" }

  # Skip these tests if ActionText is not available
  before(:each) do
    skip "ActionText is not available" unless defined?(ActionText::RichText)
  end

  describe "#extract_actiontext_content" do
    # Mock ActionText::RichText class if not available
    let(:mock_rich_text) do
      if defined?(ActionText::RichText)
        # Use actual ActionText if available
        ActionText::RichText.new(body: html_content)
      else
        # Mock it otherwise
        Class.new do
          attr_reader :body
          
          def initialize(body)
            @body = body
          end
          
          def to_s
            @body
          end
          
          def to_plain_text
            @body.gsub(/<[^>]+>/, "")
          end
        end.new(html_content)
      end
    end
    
    context "with text only" do
      let(:html_content) { "<div>This is a test message</div>" }
      
      it "extracts plain text correctly" do
        # Skip if module not loaded
        skip "ActionTextSupport module not loaded" unless chat.respond_to?(:extract_actiontext_content)
        
        result = chat.extract_actiontext_content(mock_rich_text)
        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        expect(result[0][:text]).to include("This is a test message")
      end
    end
    
    context "with text and image" do
      let(:html_content) do
        <<-HTML
          <div>Text before image</div>
          <figure>
            <img src="#{test_image_url}">
            <figcaption>Image caption</figcaption>
          </figure>
          <div>Text after image</div>
        HTML
      end
      
      it "extracts text and image correctly" do
        # Skip if module not loaded
        skip "ActionTextSupport module not loaded" unless chat.respond_to?(:extract_actiontext_content)
        
        result = chat.extract_actiontext_content(mock_rich_text)
        expect(result).to be_an(Array)
        expect(result.length).to eq(3)
        expect(result[0][:text]).to include("Text before image")
        expect(result[1][:image]).to eq(test_image_url)
        expect(result[2][:text]).to include("Text after image")
      end
    end
    
    context "with ActionText attachment" do
      let(:html_content) do
        <<-HTML
          <div>Text before attachment</div>
          <action-text-attachment sgid="test-sgid"></action-text-attachment>
          <div>Text after attachment</div>
        HTML
      end
      
      it "attempts to process action-text-attachment tags" do
        # Skip if module not loaded
        skip "ActionTextSupport module not loaded" unless chat.respond_to?(:extract_actiontext_content)
        
        # This test is mainly for code coverage, as we can't fully mock
        # the GlobalID::Locator behavior in a simple spec
        result = chat.extract_actiontext_content(mock_rich_text)
        expect(result).to be_an(Array)
        expect(result.length).to be >= 2
        expect(result[0][:text]).to include("Text before attachment")
        expect(result[-1][:text]).to include("Text after attachment")
      end
    end
  end

  describe "#messages=" do
    # This test depends on the ActionText module being loaded
    it "handles ActionText content" do
      skip "ActionTextSupport module not loaded" unless chat.respond_to?(:extract_actiontext_content)
      
      # Mock an ActionText-like object
      mock_actiontext = double("ActionText::RichText")
      allow(mock_actiontext).to receive(:is_a?).with(ActionText::RichText).and_return(true)
      allow(mock_actiontext).to receive(:to_plain_text).and_return("Plain text content")
      allow(mock_actiontext).to receive(:to_s).and_return("<div>Rich text content</div>")
      
      # Mock a message with ActionText content
      mock_message = double("Message")
      allow(mock_message).to receive(:role).and_return("user")
      allow(mock_message).to receive(:content).and_return(mock_actiontext)
      
      # Simulate the behavior when extract_actiontext_content exists
      allow(chat).to receive(:extract_actiontext_content).and_return([{text: "Parsed content"}])
      
      # Set messages
      chat.messages = [mock_message]
      
      # Verify that extract_actiontext_content was called
      expect(chat).to have_received(:extract_actiontext_content).with(mock_actiontext)
      
      # Check the message content
      expect(chat.messages.length).to eq(1)
      expect(chat.messages[0][:role]).to eq("user")
    end
  end
end