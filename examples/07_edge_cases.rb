#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "\n=== AI::Chat Edge Cases and Error Handling Tests ==="
puts

# Test 1: API key configuration variations
puts "Test 1: API key configuration"
puts "-" * 50
begin
  # Test missing API key
  original_key = ENV["OPENAI_API_KEY"]
  ENV.delete("OPENAI_API_KEY")

  begin
    AI::Chat.new
    puts "✗ Should have failed with missing API key"
  rescue KeyError => e
    puts "✓ Missing API key correctly caught:"
    puts "  #{e.message}"
  end

  # Restore key
  ENV["OPENAI_API_KEY"] = original_key

  # Test custom environment variable
  ENV["MY_CUSTOM_KEY"] = original_key
  AI::Chat.new(api_key_env_var: "MY_CUSTOM_KEY")
  puts "✓ Custom environment variable accepted"

  ENV.delete("MY_CUSTOM_KEY")
rescue => e
  puts "✗ Unexpected error: #{e.message}"
end
puts

# Test 2: Invalid model - API error propagation
puts "Test 2: Invalid model - API error propagation"
puts "-" * 50
begin
  chat = AI::Chat.new
  chat.model = "gpt-99-does-not-exist"
  chat.user("Hello")
  chat.generate!
  puts "✗ Should have raised an error"
rescue OpenAI::Errors::BadRequestError => e
  if e.message.include?("does not exist")
    puts "✓ Invalid model error correctly propagated"
  else
    puts "✗ Error propagated but message unclear: #{e.message[0..80]}..."
  end
rescue => e
  puts "✗ Unexpected error type: #{e.class} - #{e.message[0..80]}..."
end
puts

# Test 3: Invalid reasoning effort - API error propagation
puts "Test 3: Invalid reasoning effort - API error propagation"
puts "-" * 50
begin
  chat = AI::Chat.new
  chat.model = "gpt-5-nano"
  chat.reasoning_effort = "none"  # gpt-5-nano doesn't support "none"
  chat.user("Hello")
  chat.generate!
  puts "✗ Should have raised an error"
rescue OpenAI::Errors::BadRequestError => e
  if e.message.include?("none") && e.message.include?("not supported")
    puts "✓ API error correctly propagated with helpful message"
  else
    puts "✗ Error propagated but message unclear: #{e.message[0..80]}..."
  end
rescue => e
  puts "✗ Unexpected error type: #{e.class} - #{e.message[0..80]}..."
end
puts

# Test 4: Schema edge cases
puts "Test 4: Schema edge cases"
puts "-" * 50
begin
  # Empty schema
  begin
    chat = AI::Chat.new
    chat.schema = {}
    chat.user("Test")
    chat.generate!
    puts "✗ Empty schema should probably fail"
  rescue => e
    puts "✓ Empty schema handled: #{e.message[0..80]}..."
  end

  # Invalid JSON string
  begin
    chat2 = AI::Chat.new
    chat2.schema = "{ invalid json }"
    puts "✗ Invalid JSON should have failed"
  rescue => e
    puts "✓ Invalid JSON correctly rejected: #{e.message}"
  end
rescue => e
  puts "✗ Unexpected error: #{e.message}"
end
puts

puts "=== Edge Cases and Error Handling tests completed ===="
