#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "=== AI::Chat Core Functionality Test ==="
puts

# Test 1: Basic conversation
puts "Test 1: Basic conversation"
puts "-" * 30
chat1 = AI::Chat.new
chat1.user("What is 2 + 2?")
message = chat1.generate!
puts "✓ Message: #{message}"
puts "✓ Response contains answer: #{chat1.last[:content].match?(/4|four/i)}"
puts

# Test 2: Response details
puts "Test 2: Response details"
puts "-" * 30
chat5 = AI::Chat.new
chat5.user("Say hello")
chat5.generate!
response_obj = chat5.last[:response]
puts "✓ Response ID: #{response_obj[:id]}"
puts "✓ Model: #{response_obj[:model]}"
puts "✓ Usage: #{response_obj[:usage]}"
puts "✓ Total tokens: #{response_obj[:total_tokens]}"
puts

puts "=== Core tests completed successfully! ==="
