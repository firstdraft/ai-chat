# frozen_string_literal: true

require "spec_helper"

RSpec.describe AI::Chat, "messages assignment" do
  let(:chat) { build(:chat) }
  let(:test_image_path) { File.join(File.dirname(__FILE__), "../../fixtures/test1.jpg") }
  let(:test_image_url) { "https://example.com/image.jpg" }

  describe "#messages=" do
    it "replaces existing messages with new ones" do
      # Add some initial messages
      chat.system("Initial system message")
      chat.user("Initial user message")
      
      # Replace with new messages
      chat.messages = [
        { role: "system", content: "New system message" },
        { role: "user", content: "New user message" }
      ]
      
      expect(chat.messages.length).to eq(2)
      expect(chat.messages[0][:role]).to eq("system")
      expect(chat.messages[0][:content]).to eq("New system message")
      expect(chat.messages[1][:role]).to eq("user")
      expect(chat.messages[1][:content]).to eq("New user message")
    end

    it "works with string keys" do
      chat.messages = [
        { "role" => "system", "content" => "System message" },
        { "role" => "user", "content" => "User message" }
      ]
      
      expect(chat.messages.length).to eq(2)
      expect(chat.messages[0][:role]).to eq("system")
      expect(chat.messages[0][:content]).to eq("System message")
    end

    it "handles messages with images" do
      chat.messages = [
        { role: "system", content: "System message" },
        { role: "user", content: "User with image", image: test_image_path }
      ]
      
      expect(chat.messages.length).to eq(2)
      expect(chat.messages[1][:role]).to eq("user")
      expect(chat.messages[1][:content]).to be_an(Array)
      expect(chat.messages[1][:content][0][:type]).to eq("input_text")
      expect(chat.messages[1][:content][1][:type]).to eq("input_image")
    end

    it "handles messages with multiple images" do
      chat.messages = [
        { role: "user", content: "Multiple images", images: [test_image_path, test_image_url] }
      ]
      
      expect(chat.messages.length).to eq(1)
      expect(chat.messages[0][:content]).to be_an(Array)
      expect(chat.messages[0][:content].length).to eq(3) # text + 2 images
    end

    it "works with custom attribute mappings" do
      chat.configure_attributes(
        role: :message_type,
        content: :message_body
      )
      
      chat.messages = [
        { message_type: "system", message_body: "System with custom mapping" },
        { message_type: "user", message_body: "User with custom mapping" }
      ]
      
      expect(chat.messages.length).to eq(2)
      expect(chat.messages[0][:role]).to eq("system")
      expect(chat.messages[0][:content]).to eq("System with custom mapping")
    end
    
    # Mock an ActiveRecord-like object
    class MockMessage
      attr_reader :message_type, :message_body
      
      def initialize(type, body)
        @message_type = type
        @message_body = body
      end
    end
    
    class MockMessageWithImage < MockMessage
      attr_reader :image
      
      def initialize(type, body, image)
        super(type, body)
        @image = image
      end
    end
    
    class MockMessageWithImages < MockMessage
      attr_reader :attachments
      
      def initialize(type, body, attachments)
        super(type, body)
        @attachments = attachments
      end
    end
    
    class MockImage
      attr_reader :url
      
      def initialize(url)
        @url = url
      end
    end
    
    it "works with object methods (ActiveRecord-like)" do
      chat.configure_attributes(
        role: :message_type,
        content: :message_body
      )
      
      mock_messages = [
        MockMessage.new("system", "System from object"),
        MockMessage.new("user", "User from object")
      ]
      
      chat.messages = mock_messages
      
      expect(chat.messages.length).to eq(2)
      expect(chat.messages[0][:role]).to eq("system")
      expect(chat.messages[0][:content]).to eq("System from object")
    end
    
    it "handles objects with image attributes" do
      chat.configure_attributes(
        role: :message_type,
        content: :message_body,
        image: :image
      )
      
      mock_messages = [
        MockMessage.new("system", "System message"),
        MockMessageWithImage.new("user", "Message with image", test_image_path)
      ]
      
      chat.messages = mock_messages
      
      expect(chat.messages.length).to eq(2)
      expect(chat.messages[1][:role]).to eq("user")
      expect(chat.messages[1][:content]).to be_an(Array)
      expect(chat.messages[1][:content][0][:type]).to eq("input_text")
      expect(chat.messages[1][:content][1][:type]).to eq("input_image")
    end
    
    it "handles objects with image collections" do
      chat.configure_attributes(
        role: :message_type,
        content: :message_body,
        images: :attachments,
        image_url: :url
      )
      
      mock_images = [
        MockImage.new(test_image_path),
        MockImage.new(test_image_url)
      ]
      
      mock_messages = [
        MockMessage.new("system", "System message"),
        MockMessageWithImages.new("user", "Message with images", mock_images)
      ]
      
      chat.messages = mock_messages
      
      expect(chat.messages.length).to eq(2)
      expect(chat.messages[1][:role]).to eq("user")
      expect(chat.messages[1][:content]).to be_an(Array)
      expect(chat.messages[1][:content].length).to eq(3) # text + 2 images
    end
  end
end