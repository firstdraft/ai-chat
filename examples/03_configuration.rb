#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "\n=== AI::Chat Configuration Tests ==="
puts

# Test 1: API key configuration
puts "Test 1: API key configuration"
puts "-" * 30
# Test with environment variable
begin
  AI::Chat.new
  puts "✓ Default OPENAI_API_KEY works"
rescue => e
  puts "✗ Default OPENAI_API_KEY failed: #{e.message}"
end

# Test with custom env var
ENV["CUSTOM_KEY"] = ENV["OPENAI_API_KEY"]
begin
  AI::Chat.new(api_key_env_var: "CUSTOM_KEY")
  puts "✓ Custom environment variable works"
rescue => e
  puts "✗ Custom environment variable failed: #{e.message}"
end
ENV.delete("CUSTOM_KEY")

# Test with direct API key
begin
  AI::Chat.new(api_key: ENV["OPENAI_API_KEY"])
  puts "✓ Direct API key works"
rescue => e
  puts "✗ Direct API key failed: #{e.message}"
end
puts

# Test 2: Different model configurations
puts "Test 2: Different model configurations"
puts "-" * 30
models = ["gpt-4.1-nano", "gpt-4o-mini", "gpt-4o"]
models.each do |model|
  chat = AI::Chat.new
  chat.model = model
  chat.user("Say 'Hello' in exactly 5 characters")
  response = chat.generate!
  puts "✓ Model #{model}: #{response}"
rescue => e
  puts "✗ Model #{model} error: #{e.message}"
end
puts

# Test 3: Reasoning effort configuration (for o-series models)
puts "Test 3: Reasoning effort configuration"
puts "-" * 30
chat3 = AI::Chat.new
chat3.model = "o1-mini"
puts "Testing reasoning effort levels..."
["low", "medium", "high", :low].each do |level|
  chat3.reasoning_effort = level
  puts "  Set reasoning_effort to #{level} (#{level.class}) - OK"
rescue => e
  puts "  Set reasoning_effort to #{level} - ERROR: #{e.message}"
end

# Test invalid value
begin
  chat3.reasoning_effort = "invalid"
rescue ArgumentError => e
  puts "  Invalid reasoning_effort correctly raises error: #{e.message}"
end

# Test nil value
chat3.reasoning_effort = nil
puts "  Set reasoning_effort to nil - OK"
puts

puts "=== Configuration tests completed ===="
