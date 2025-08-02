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
  response = chat1.generate!
  puts "✓ PDF with .pdf extension handled correctly"
  puts "  Response: #{response[0..100]}..."
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
  response = chat2.generate!
  puts "✓ PDF without extension detected and handled correctly"
  puts "  Response: #{response[0..100]}..."

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
  response = chat3.generate!
  puts "✓ PDF with wrong extension (.txt) still detected as PDF"
  puts "  Response: #{response[0..100]}..."

  temp_file.close
  temp_file.unlink
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 4: Various text file types
puts "Test 4: Various text file types"
puts "-" * 50
text_files = {
  "Ruby code (.rb)" => ["test.rb", "def hello\n  puts 'Hello, world!'\nend"],
  "Python code (.py)" => ["test.py", "def hello():\n    print('Hello, world!')"],
  "JavaScript (.js)" => ["test.js", "function hello() {\n  console.log('Hello, world!');\n}"],
  "JSON (.json)" => ["test.json", '{"message": "Hello, world!", "count": 42}'],
  "YAML (.yml)" => ["test.yml", "message: Hello, world!\ncount: 42"],
  "CSV (.csv)" => ["test.csv", "name,age,city\nAlice,30,Boston\nBob,25,NYC"],
  "Markdown (.md)" => ["test.md", "# Hello\n\nThis is a **markdown** file."],
  "Plain text (.txt)" => ["test.txt", "This is plain text content."],
  "Config file (.conf)" => ["test.conf", "server.port=8080\nserver.host=localhost"],
  "No extension" => ["testfile", "File with no extension"]
}

text_files.each do |description, (filename, content)|
  temp_file = Tempfile.new(filename)
  temp_file.write(content)
  temp_file.rewind

  chat = AI::Chat.new
  chat.user("What kind of file is this and what does it contain?", file: temp_file.path)
  response = chat.generate!
  puts "✓ #{description}: AI understood content"
  puts "  Response: #{response[0..80]}..."

  temp_file.close
  temp_file.unlink
rescue => e
  puts "✗ #{description}: #{e.message}"
end
puts

# Test 5: Rails-style file uploads (simulating ActionDispatch::Http::UploadedFile)
puts "Test 5: Rails-style file uploads"
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
  response = chat5a.generate!
  puts "✓ Rails PDF upload handled correctly"
  puts "  Response: #{response[0..100]}..."
  pdf_upload.close

  # Test with text file upload
  temp_file = Tempfile.new(["upload", ".rb"])
  temp_file.write("class User < ApplicationRecord\n  validates :email, presence: true\nend")
  temp_file.rewind

  text_upload = FakeUploadedFile.new(temp_file.path, "user.rb", "text/x-ruby")

  chat5b = AI::Chat.new
  chat5b.user("What Rails model is defined in this uploaded file?", file: text_upload)
  response = chat5b.generate!
  puts "✓ Rails text file upload handled correctly"
  puts "  Response: #{response[0..100]}..."

  text_upload.close
  temp_file.close
  temp_file.unlink
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 6: URL file handling
puts "Test 6: URL file handling"
puts "-" * 50
begin
  # Note: We're trusting the user to specify the correct parameter (file: vs image:)
  chat6 = AI::Chat.new
  chat6.user("Describe this image", image: "https://picsum.photos/200/300")
  response = chat6.generate!
  puts "✓ Image URL handled correctly"
  puts "  Response: #{response[0..100]}..."

  # For PDF URLs, user would use file: parameter
  # chat.user("Analyze this PDF", file: "https://example.com/document.pdf")
  puts "ℹ️  Note: For PDF URLs, use file: parameter (not tested with live URL)"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 7: Binary file handling (should fail gracefully)
puts "Test 7: Binary file handling (expected to fail)"
puts "-" * 50
begin
  # Create a binary file
  temp_file = Tempfile.new(["binary", ".bin"])
  temp_file.binmode
  temp_file.write([0x00, 0xFF, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC].pack("C*"))
  temp_file.rewind

  chat7 = AI::Chat.new
  chat7.user("What is this file?", file: temp_file.path)
  chat7.generate!
  puts "✗ Binary file should have failed but didn't"

  temp_file.close
  temp_file.unlink
rescue AI::Chat::InputClassificationError => e
  puts "✓ Binary file correctly rejected with clear error:"
  puts "  #{e.message}"
rescue => e
  puts "✗ Unexpected error: #{e.message}"
end
puts

# Test 8: File-like objects without proper methods
puts "Test 8: File-like objects without proper methods"
puts "-" * 50
begin
  # Create an object that has read but no filename methods
  bad_file = StringIO.new("Some content")

  chat8 = AI::Chat.new
  chat8.user("Read this", file: bad_file)
  chat8.generate!
  puts "✗ Should have failed with missing filename error"
rescue AI::Chat::InputClassificationError => e
  puts "✓ File object without filename methods correctly rejected:"
  puts "  #{e.message}"
rescue => e
  puts "✗ Unexpected error: #{e.message}"
end
puts

# Test 9: Multiple files with mixed types
puts "Test 9: Multiple files with mixed types"
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
  response = chat9.generate!
  puts "✓ Multiple text files handled correctly"
  puts "  Response: #{response[0..150]}..."

  files.each { |f|
    f.close
    f.unlink
  }
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

puts "=== Comprehensive File Handling tests completed ===="
