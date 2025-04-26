# frozen_string_literal: true

require "spec_helper"

RSpec.describe AI::Chat, "image support" do
  let(:test_image1_path) { File.join(File.dirname(__FILE__), "../../fixtures/test1.jpg") }
  let(:test_image2_path) { File.join(File.dirname(__FILE__), "../../fixtures/test2.jpg") }
  let(:test_image3_path) { File.join(File.dirname(__FILE__), "../../fixtures/test3.jpg") }
  let(:test_image_url) { "https://example.com/image.jpg" }
  let(:chat) { build(:chat) }

  describe "#process_image" do
    context "with a URL" do
      it "returns the URL unchanged" do
        result = chat.send(:process_image, test_image_url)
        expect(result).to eq(test_image_url)
      end
    end

    context "with a file path" do
      it "converts the file to a base64 data URI" do
        result = chat.send(:process_image, test_image1_path)

        expect(result).to start_with("data:image/jpeg;base64,")

        # Decode the base64 data and verify it matches the original file
        base64_data = result.split(",").last
        decoded_data = Base64.strict_decode64(base64_data)

        expect(decoded_data).to eq(File.binread(test_image1_path))
      end
    end

    context "with a file-like object" do
      it "converts the file content to a base64 data URI" do
        file = File.open(test_image1_path)
        result = chat.send(:process_image, file)

        expect(result).to start_with("data:image/jpeg;base64,")

        # Decode the base64 data and verify it matches the original file
        base64_data = result.split(",").last
        decoded_data = Base64.strict_decode64(base64_data)

        expect(decoded_data).to eq(File.binread(test_image1_path))

        # Check that the file pointer has been reset
        expect(file.pos).to eq(0)

        file.close
      end

      it "handles StringIO objects" do
        content = File.binread(test_image1_path)
        string_io = StringIO.new(content)

        result = chat.send(:process_image, string_io)

        expect(result).to start_with("data:image/jpeg;base64,")

        # Decode the base64 data and verify it matches the original content
        base64_data = result.split(",").last
        decoded_data = Base64.strict_decode64(base64_data)

        expect(decoded_data).to eq(content)
      end
    end
  end

  describe "#user" do
    context "with a single image" do
      it "formats the message correctly with an image" do
        chat.user("Test with image", image: test_image1_path)

        last_message = chat.messages.last
        expect(last_message[:role]).to eq("user")
        expect(last_message[:content]).to be_an(Array)
        expect(last_message[:content].length).to eq(2)

        # Text content
        expect(last_message[:content][0][:type]).to eq("text")
        expect(last_message[:content][0][:text]).to eq("Test with image")

        # Image content
        expect(last_message[:content][1][:type]).to eq("image_url")
        expect(last_message[:content][1][:image_url][:url]).to start_with("data:image/jpeg;base64,")
      end

      it "formats the message correctly with an image URL" do
        chat.user("Test with image URL", image: test_image_url)

        last_message = chat.messages.last
        expect(last_message[:role]).to eq("user")
        expect(last_message[:content]).to be_an(Array)

        # Image content
        expect(last_message[:content][1][:type]).to eq("image_url")
        expect(last_message[:content][1][:image_url][:url]).to eq(test_image_url)
      end
    end

    context "with multiple images" do
      it "formats the message correctly with multiple images" do
        chat.user("Test with multiple images", images: [test_image1_path, test_image_url])

        last_message = chat.messages.last
        expect(last_message[:role]).to eq("user")
        expect(last_message[:content]).to be_an(Array)
        expect(last_message[:content].length).to eq(3) # Text + 2 images

        # Text content
        expect(last_message[:content][0][:type]).to eq("text")
        expect(last_message[:content][0][:text]).to eq("Test with multiple images")

        # First image (file path)
        expect(last_message[:content][1][:type]).to eq("image_url")
        expect(last_message[:content][1][:image_url][:url]).to start_with("data:image/jpeg;base64,")

        # Second image (URL)
        expect(last_message[:content][2][:type]).to eq("image_url")
        expect(last_message[:content][2][:image_url][:url]).to eq(test_image_url)
      end

      it "formats the message correctly with multiple local images" do
        chat.user("Test with multiple local images", images: [test_image1_path, test_image2_path, test_image3_path])

        last_message = chat.messages.last
        expect(last_message[:role]).to eq("user")
        expect(last_message[:content]).to be_an(Array)
        expect(last_message[:content].length).to eq(4) # Text + 3 images

        # Text content
        expect(last_message[:content][0][:type]).to eq("text")
        expect(last_message[:content][0][:text]).to eq("Test with multiple local images")

        # All images should be base64 encoded
        expect(last_message[:content][1][:type]).to eq("image_url")
        expect(last_message[:content][1][:image_url][:url]).to start_with("data:image/jpeg;base64,")
        
        expect(last_message[:content][2][:type]).to eq("image_url")
        expect(last_message[:content][2][:image_url][:url]).to start_with("data:image/jpeg;base64,")
        
        expect(last_message[:content][3][:type]).to eq("image_url")
        expect(last_message[:content][3][:image_url][:url]).to start_with("data:image/jpeg;base64,")
      end
    end

    context "with direct array content" do
      it "uses the array as is when passed directly" do
        custom_content = [
          {type: "text", text: "Custom message with direct array"},
          {
            type: "image_url",
            image_url: {
              url: test_image_url,
              detail: "high"
            }
          }
        ]

        chat.user(custom_content)

        last_message = chat.messages.last
        expect(last_message[:role]).to eq("user")
        expect(last_message[:content]).to eq(custom_content)
        expect(last_message[:content]).to be_an(Array)
        expect(last_message[:content].length).to eq(2)

        # Image content with custom parameters
        expect(last_message[:content][1][:type]).to eq("image_url")
        expect(last_message[:content][1][:image_url][:url]).to eq(test_image_url)
        expect(last_message[:content][1][:image_url][:detail]).to eq("high")
      end

      it "processes simplified image/text format correctly" do
        simplified_content = [
          {"text" => "A message with simplified format"},
          {"image" => test_image1_path},
          {"image" => test_image_url}
        ]

        chat.user(simplified_content)

        last_message = chat.messages.last
        expect(last_message[:role]).to eq("user")
        expect(last_message[:content]).to be_an(Array)
        expect(last_message[:content].length).to eq(3)

        # Text content
        expect(last_message[:content][0][:type]).to eq("text")
        expect(last_message[:content][0][:text]).to eq("A message with simplified format")

        # First image (file path)
        expect(last_message[:content][1][:type]).to eq("image_url")
        expect(last_message[:content][1][:image_url][:url]).to start_with("data:image/jpeg;base64,")

        # Second image (URL)
        expect(last_message[:content][2][:type]).to eq("image_url")
        expect(last_message[:content][2][:image_url][:url]).to eq(test_image_url)
      end

      it "processes multiple local images with simplified format" do
        simplified_content = [
          {"text" => "A message with multiple local images"},
          {"image" => test_image1_path},
          {"image" => test_image2_path},
          {"image" => test_image3_path}
        ]

        chat.user(simplified_content)

        last_message = chat.messages.last
        expect(last_message[:role]).to eq("user")
        expect(last_message[:content]).to be_an(Array)
        expect(last_message[:content].length).to eq(4)

        # Text content
        expect(last_message[:content][0][:type]).to eq("text")
        expect(last_message[:content][0][:text]).to eq("A message with multiple local images")

        # All images should be base64 encoded
        expect(last_message[:content][1][:type]).to eq("image_url")
        expect(last_message[:content][1][:image_url][:url]).to start_with("data:image/jpeg;base64,")
        
        expect(last_message[:content][2][:type]).to eq("image_url")
        expect(last_message[:content][2][:image_url][:url]).to start_with("data:image/jpeg;base64,")
        
        expect(last_message[:content][3][:type]).to eq("image_url")
        expect(last_message[:content][3][:image_url][:url]).to start_with("data:image/jpeg;base64,")
      end
    end
  end

  describe "#classify_obj" do
    it "classifies URLs correctly" do
      result = chat.send(:classify_obj, "https://example.com/image.jpg")
      expect(result).to eq(:url)
    end

    it "classifies file paths correctly" do
      result = chat.send(:classify_obj, test_image1_path)
      expect(result).to eq(:file_path)
    end

    it "classifies file-like objects correctly" do
      file = File.open(test_image1_path)
      result = chat.send(:classify_obj, file)
      expect(result).to eq(:file_like)
      file.close
    end

    it "raises an error for non-existent file paths" do
      expect {
        chat.send(:classify_obj, "/path/to/nonexistent/file.jpg")
      }.to raise_error(AI::Chat::InputClassificationError)
    end

    it "raises an error for objects that don't respond to read" do
      expect {
        chat.send(:classify_obj, Object.new)
      }.to raise_error(AI::Chat::InputClassificationError)
    end
  end
end
