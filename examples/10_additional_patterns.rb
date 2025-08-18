#!/usr/bin/env ruby

# Additional usage patterns not covered in other examples
# This file demonstrates less common but valid ways to use AI::Chat

require "dotenv/load"
require_relative "../lib/ai-chat"
require "tempfile"
require "fileutils"

puts "=== AI::Chat Additional Usage Patterns ==="
puts

# Note: System messages only support text content, not images or files.
# This is a limitation of the OpenAI API, not this gem.

puts "Test 1: Using the add method directly"
puts "-" * 50
chat1 = AI::Chat.new
chat1.add("Hello from add method", role: "user")
chat1.add("Hi there! I see you're using the add method directly.", role: "assistant")
chat1.add("Yes, showing that we can build conversations manually", role: "user")
puts "✓ Built conversation with add method:"
puts "  Messages count: #{chat1.messages.length}"
puts

puts "Test 2: Web search with structured output"
puts "-" * 50
begin
  chat2 = AI::Chat.new
  chat2.model = "gpt-4o"  # Model that supports both features
  chat2.web_search = true
  chat2.schema = {
    type: "object",
    properties: {
      answer: {type: "string"},
      sources_found: {type: "boolean"}
    },
    required: ["answer", "sources_found"],
    additionalProperties: false
  }
  chat2.user("What is the current population of Tokyo in 2025?")
  response = chat2.generate!
  puts "✓ Web search + structured output: #{response}"
rescue => e
  puts "✗ Web search + structured output error: #{e.message}"
end
puts

puts "Test 3: File paths with spaces and unicode"
puts "-" * 50
begin
  # Create a file with spaces and unicode in the name
  temp_dir = Dir.mktmpdir("ai chat test")
  file_path = File.join(temp_dir, "test file with spaces €.txt")
  File.write(file_path, "Content from file with spaces and unicode in path")

  chat3 = AI::Chat.new
  chat3.user("What's in this file?", file: file_path)
  response = chat3.generate!
  puts "✓ Handled file path with spaces and unicode"
  puts "  Response: #{response[0..100]}..."

  FileUtils.rm_rf(temp_dir)
rescue => e
  puts "✗ File path with spaces error: #{e.message}"
end
puts

puts "Test 4: Chaining with web search"
puts "-" * 50
begin
  # First chat searches the web
  chat4a = AI::Chat.new
  chat4a.model = "gpt-4o"
  chat4a.web_search = true
  chat4a.user("What's the latest Ruby version released?")
  response = chat4a.generate!
  puts "✓ First chat with web search: #{response[0..100]}..."

  # Chain to second chat
  response_id = chat4a.last.dig(:response, :id)
  chat4b = AI::Chat.new
  chat4b.model = "gpt-4o"
  chat4b.previous_response_id = response_id
  chat4b.user("Is this version stable for production use?")
  response = chat4b.generate!
  puts "✓ Chained response: #{response[0..100]}..."
rescue => e
  puts "✗ Web search chaining error: #{e.message}"
end
puts

puts "Test 5: Manually passing response objects"
puts "-" * 50
chat5 = AI::Chat.new
# Simulate building a conversation with manual response tracking
chat5.user("What's 2+2?")
chat5.generate!
response_obj = chat5.last[:response]

# Manually add assistant message with response object
chat5.assistant("Let me calculate: 2+2=4", response: response_obj)
puts "✓ Manually added assistant message with response object"
puts "  Message has response: #{chat5.last.key?(:response)}"
puts

puts "Test 6: Schema as JSON string"
puts "-" * 50
chat6 = AI::Chat.new
chat6.schema = '{"type": "object", "properties": {"result": {"type": "number"}}, "required": ["result"], "additionalProperties": false}'
chat6.user("What's 10 times 5?")
response = chat6.generate!
puts "✓ Schema from JSON string: #{response}"
puts

puts "Test 7: Empty content edge cases"
puts "-" * 50
chat7 = AI::Chat.new
chat7.user("")  # Empty string
chat7.user(" ")  # Whitespace only
chat7.user("\n\t")  # Just whitespace characters
puts "✓ Empty/whitespace messages accepted"
puts "  Total messages: #{chat7.messages.length}"
puts

puts "Test 8: Mixed multimodal in conversation"
puts "-" * 50
begin
  chat8 = AI::Chat.new
  chat8.model = "gpt-4o"

  # Create test files
  text_file = Tempfile.new(["content", ".txt"])
  text_file.write("This is a text file")
  text_file.close

  # User message with file
  chat8.user("Here's a text file", file: text_file.path)

  # Assistant response
  chat8.assistant("I see the text file contains 'This is a text file'")

  # Another user message with different file type
  pdf_file = Tempfile.new(["document", ".pdf"])
  pdf_file.write("%PDF-1.4\n%Fake PDF content")
  pdf_file.close

  chat8.user("Now here's a PDF", file: pdf_file.path)

  puts "✓ Mixed multimodal conversation built"
  puts "  Messages: #{chat8.messages.length}"
  puts "  Message types: #{chat8.messages.map { |m| m[:content].is_a?(Array) ? "multimodal" : "text" }}"

  text_file.unlink
  pdf_file.unlink
rescue => e
  puts "✗ Mixed multimodal error: #{e.message}"
end

puts "\n=== Additional Patterns Test Complete ==="
