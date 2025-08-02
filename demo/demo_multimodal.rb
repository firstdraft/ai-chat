#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "\n=== AI::Chat Multimodal Tests ==="
puts

# Test 1: Image handling (with URL)
puts "Test 1: Image handling with URL"
puts "-" * 30
chat1 = AI::Chat.new
chat1.user("What do you see in this image?", image: "https://picsum.photos/200/300")
response = chat1.generate!
puts "✓ Image description: #{response[0..100]}..."
puts

# Test 2: PDF file processing with structured output
puts "Test 2: PDF file processing with structured output"
puts "-" * 30
begin
  pdf_path = File.expand_path("../spec/fixtures/test.pdf", __dir__)

  if File.exist?(pdf_path)
    chat2 = AI::Chat.new
    chat2.system("Extract data from the provided PDF file")

    schema = {
      name: "InvoiceData",
      strict: true,
      schema: {
        type: "object",
        properties: {
          items: {
            type: "array",
            items: {
              type: "object",
              properties: {
                item_code: {type: "number"},
                item_desc: {type: "string"},
                unit_price: {type: "number"},
                quantity: {type: "integer"},
                total: {type: "number"}
              },
              required: ["item_code", "item_desc", "unit_price", "quantity", "total"],
              additionalProperties: false
            }
          }
        },
        required: ["items"],
        additionalProperties: false
      }
    }

    chat2.schema = schema
    chat2.user("Extract the invoice data from this PDF", file: pdf_path)

    response = chat2.generate!
    puts "✓ PDF data extracted:"
    ap response
    puts "✓ Response is a Hash: #{response.is_a?(Hash)}"
  else
    puts "✗ Test PDF not found at #{pdf_path}"
  end
rescue => e
  puts "✗ Error: #{e.message}"
  puts "  #{e.backtrace.first(3).join("\n  ")}"
end
puts

# Test 3: Single file handling
puts "Test 3: Single file handling"
puts "-" * 30
begin
  file_path = File.expand_path("../README.md", __dir__)

  chat3 = AI::Chat.new
  chat3.user("Summarize this file in one sentence", file: file_path)
  response = chat3.generate!
  puts "✓ File summary: #{response}"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 4: Multiple files handling
puts "Test 4: Multiple files handling"
puts "-" * 30
begin
  file1 = File.expand_path("../README.md", __dir__)
  file2 = File.expand_path("../CHANGELOG.md", __dir__)

  if File.exist?(file1) && File.exist?(file2)
    chat4 = AI::Chat.new
    chat4.user("Compare these two files and tell me their purposes", files: [file1, file2])
    response = chat4.generate!
    puts "✓ Files comparison: #{response[0..200]}..."
  else
    puts "✗ One or more files not found"
  end
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 5: Mixed content types (text + image)
puts "Test 5: Mixed content types (text + image)"
puts "-" * 30
begin
  chat5 = AI::Chat.new
  chat5.system("You are an image analyst")
  chat5.user("Describe this image", image: "https://picsum.photos/200/300")
  chat5.generate!

  chat5.user("Now tell me a joke about what you saw")
  response = chat5.generate!
  puts "✓ Mixed content response: #{response}"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

puts "=== Multimodal tests completed ===="
