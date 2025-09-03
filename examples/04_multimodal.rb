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
response = chat1.generate![:content]
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

    message = chat2.generate![:content]
    puts "✓ PDF data extracted:"
    ap message
    puts "✓ Message is a Hash: #{message.is_a?(Hash)}"
  else
    puts "✗ Test PDF not found at #{pdf_path}"
  end
rescue => e
  puts "✗ Error: #{e.message}"
  puts "  #{e.backtrace.first(3).join("\n  ")}"
end
puts

# Test 3: Single file handling (non-PDF text files)
puts "Test 3: Single file handling (non-PDF text files)"
puts "-" * 30
begin
  file_path = File.expand_path("../README.md", __dir__)
  puts "Testing with: #{File.basename(file_path)} (Markdown file)"

  chat3 = AI::Chat.new
  chat3.user("What is the first line of this file?", file: file_path)
  message = chat3.generate!
  puts "✓ AI correctly read file content: #{message}"

  # Also test file summarization
  chat3.user("Now summarize this same file in one sentence", file: file_path)
  message = chat3.generate![:content]
  puts "✓ File summary: #{message}"
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
    message = chat4.generate![:content]
    puts "✓ Files comparison: #{message[0..200]}..."
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
  message = chat5.generate![:content]
  puts "✓ Mixed content message: #{message}"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

puts "=== Multimodal tests completed ===="
