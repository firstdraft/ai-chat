#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "tempfile"

puts "\n=== AI::Chat Mixed Content Types Test ==="
puts

# Test 1: Single image + single file
puts "Test 1: Single image + single file in one message"
puts "-" * 50
begin
  chat1 = AI::Chat.new

  # Create a test file
  test_file = Tempfile.new(["test", ".txt"])
  test_file.write("This is test content for mixed media message")
  test_file.close

  chat1.user(
    "What do you see in this image and what's in the text file?",
    image: "https://picsum.photos/200/300",
    file: test_file.path
  )

  message = chat1.generate![:content]
  puts "✓ Single image + single file worked"
  puts "  Message: #{message[0..150]}..."

  test_file.unlink
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 2: Multiple images + multiple files
puts "Test 2: Multiple images + multiple files"
puts "-" * 50
begin
  chat2 = AI::Chat.new

  # Create test files
  file1 = Tempfile.new(["code", ".rb"])
  file1.write("def hello\n  puts 'Hello World'\nend")
  file1.close

  file2 = Tempfile.new(["data", ".json"])
  file2.write('{"name": "test", "value": 42}')
  file2.close

  chat2.user(
    "Analyze these images and files",
    images: ["https://picsum.photos/200/200", "https://picsum.photos/300/200"],
    files: [file1.path, file2.path]
  )

  message = chat2.generate![:content]
  puts "✓ Multiple images + multiple files worked"
  puts "  Message: #{message[0..150]}..."

  file1.unlink
  file2.unlink
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 3: Mixed singular and plural parameters
puts "Test 3: Mixed singular and plural (image + images, file + files)"
puts "-" * 50
begin
  chat3 = AI::Chat.new

  # Create test files
  single_file = Tempfile.new(["single", ".txt"])
  single_file.write("Single file content")
  single_file.close

  multi_file1 = Tempfile.new(["multi1", ".txt"])
  multi_file1.write("First file in array")
  multi_file1.close

  multi_file2 = Tempfile.new(["multi2", ".txt"])
  multi_file2.write("Second file in array")
  multi_file2.close

  chat3.user(
    "Count how many images and text files you received",
    image: "https://picsum.photos/100/100",
    images: ["https://picsum.photos/150/150", "https://picsum.photos/200/150"],
    file: single_file.path,
    files: [multi_file1.path, multi_file2.path]
  )

  message = chat3.generate![:content]
  puts "✓ Mixed singular + plural parameters worked"
  puts "  Message: #{message[0..150]}..."

  single_file.unlink
  multi_file1.unlink
  multi_file2.unlink
rescue => e
  puts "✗ Error: #{e.message}"
  puts "  Backtrace: #{e.backtrace[0..3].join("\n  ")}"
end
puts

# Test 4: PDF + images + text files
puts "Test 4: PDF + images + text files"
puts "-" * 50
begin
  chat4 = AI::Chat.new

  # Use real PDF if available
  pdf_path = File.expand_path("../spec/fixtures/test.pdf", __dir__)

  if File.exist?(pdf_path)
    # Create a text file
    text_file = Tempfile.new(["notes", ".txt"])
    text_file.write("These are my notes about the invoice")
    text_file.close

    chat4.user(
      "Analyze this invoice PDF, the image, and my notes",
      file: pdf_path,
      image: "https://picsum.photos/200/200",
      files: [text_file.path]
    )

    message = chat4.generate![:content]
    puts "✓ PDF + image + text file worked"
    puts "  Message: #{message[0..150]}..."

    text_file.unlink
  else
    puts "ℹ️  Skipping PDF test (test PDF not found)"
  end
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

puts "=== Mixed Content Types Test Complete ==="
