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
  response = chat.generate![:content]
  puts "✓ Model #{model}: #{response}"
rescue => e
  puts "✗ Model #{model} error: #{e.message}"
end
puts

puts "=== Configuration tests completed ===="
