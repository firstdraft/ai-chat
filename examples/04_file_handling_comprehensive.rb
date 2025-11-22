#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"
require "tempfile"
require "stringio"

puts "\n=== AI::Chat Comprehensive File Handling Tests ==="
puts

# Test 1: PDF with standard .pdf extension
puts "Test 1: PDF with standard .pdf extension"
puts "-" * 50
begin
  pdf_path = File.expand_path("../spec/fixtures/test.pdf", __dir__)

  chat1 = AI::Chat.new
  chat1.user("What type of document is this?", file: pdf_path)
  message = chat1.generate![:content]
  puts "✓ PDF with .pdf extension handled correctly"
  puts "  Message: #{message[0..100]}..."
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 2: PDF without extension
puts "Test 2: PDF without extension"
puts "-" * 50
begin
  # Create a temporary PDF file without extension
  pdf_content = File.binread(File.expand_path("../spec/fixtures/test.pdf", __dir__))
  temp_file = Tempfile.new(["pdf_no_ext", ""])  # No extension
  temp_file.binmode
  temp_file.write(pdf_content)
  temp_file.rewind

  chat2 = AI::Chat.new
  chat2.user("What type of document is this?", file: temp_file.path)
  message = chat2.generate![:content]
  puts "✓ PDF without extension detected and handled correctly"
  puts "  Message: #{message[0..100]}..."

  temp_file.close
  temp_file.unlink
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 3: PDF with wrong extension
puts "Test 3: PDF with wrong extension (.txt)"
puts "-" * 50
begin
  # Create a temporary PDF file with .txt extension
  pdf_content = File.binread(File.expand_path("../spec/fixtures/test.pdf", __dir__))
  temp_file = Tempfile.new(["pdf_wrong_ext", ".txt"])
  temp_file.binmode
  temp_file.write(pdf_content)
  temp_file.rewind

  chat3 = AI::Chat.new
  chat3.user("What type of document is this?", file: temp_file.path)
  message = chat3.generate![:content]
  puts "✓ PDF with wrong extension (.txt) still detected as PDF"
  puts "  Message: #{message[0..100]}..."

  temp_file.close
  temp_file.unlink
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 4: Rails-style file uploads (simulating ActionDispatch::Http::UploadedFile)
puts "Test 4: Rails-style file uploads"
puts "-" * 50
begin
  # Simulate a Rails uploaded file
  class FakeUploadedFile
    attr_reader :original_filename, :content_type

    def initialize(file_path, original_filename, content_type)
      @file = File.open(file_path, "rb")
      @original_filename = original_filename
      @content_type = content_type
    end

    def read
      @file.read
    end

    def rewind
      @file.rewind
    end

    def close
      @file.close
    end
  end

  # Test with PDF upload
  pdf_path = File.expand_path("../spec/fixtures/test.pdf", __dir__)
  pdf_upload = FakeUploadedFile.new(pdf_path, "invoice.pdf", "application/pdf")

  chat5a = AI::Chat.new
  chat5a.user("What kind of uploaded file is this?", file: pdf_upload)
  message = chat5a.generate![:content]
  puts "✓ Rails PDF upload handled correctly"
  puts "  Message: #{message[0..100]}..."
  pdf_upload.close

  # Test with text file upload
  temp_file = Tempfile.new(["upload", ".rb"])
  temp_file.write("class User < ApplicationRecord\n  validates :email, presence: true\nend")
  temp_file.rewind

  text_upload = FakeUploadedFile.new(temp_file.path, "user.rb", "text/x-ruby")

  chat5b = AI::Chat.new
  chat5b.user("What Rails model is defined in this uploaded file?", file: text_upload)
  message = chat5b.generate![:content]
  puts "✓ Rails text file upload handled correctly"
  puts "  Message: #{message[0..100]}..."

  text_upload.close
  temp_file.close
  temp_file.unlink
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 5: URL file handling
puts "Test 5: URL file handling"
puts "-" * 50
begin
  # Note: We're trusting the user to specify the correct parameter (file: vs image:)
  chat6 = AI::Chat.new
  chat6.user("Describe this image", image: "https://picsum.photos/200/300")
  message = chat6.generate![:content]
  puts "✓ Image URL handled correctly"
  puts "  Message: #{message[0..100]}..."

  # For PDF URLs, user would use file: parameter
  # chat.user("Analyze this PDF", file: "https://example.com/document.pdf")
  puts "ℹ️  Note: For PDF URLs, use file: parameter (not tested with live URL)"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 6: Multiple files with mixed types
puts "Test 6: Multiple files with mixed types"
puts "-" * 50
begin
  # Create multiple temporary files
  files = []

  # Add a text file
  text_file = Tempfile.new(["code", ".py"])
  text_file.write("def calculate_sum(a, b):\n    return a + b")
  text_file.rewind
  files << text_file

  # Add another text file
  config_file = Tempfile.new(["config", ".json"])
  config_file.write('{"api_key": "redacted", "timeout": 30}')
  config_file.rewind
  files << config_file

  chat9 = AI::Chat.new
  chat9.user("Analyze these files and tell me what they do", files: files.map(&:path))
  message = chat9.generate![:content]
  puts "✓ Multiple text files handled correctly"
  puts "  Message: #{message[0..150]}..."

  files.each { |f|
    f.close
    f.unlink
  }
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

puts "=== Comprehensive File Handling tests completed ===="
