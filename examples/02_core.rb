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

# Test 2: Conversation and Response IDs
puts "Test 2: Conversation and Response IDs"
puts "-" * 30
chat2 = AI::Chat.new
chat2.user("My name is Bob.")
chat2.generate!
puts "✓ Conversation ID created: #{chat2.conversation_id}"
puts "✓ Last Response ID created: #{chat2.last_response_id}"
first_resp_id = chat2.last_response_id

chat2.user("What is my name?")
chat2.generate!
puts "✓ Conversation ID is maintained: #{chat2.conversation_id}"
puts "✓ Last Response ID is updated: #{chat2.last_response_id}"
puts "✓ New response ID is different: #{chat2.last_response_id != first_resp_id}"
puts

# Test 3: Response details
puts "Test 3: Response details"
puts "-" * 30
chat3 = AI::Chat.new
chat3.user("Say hello")
chat3.generate!
response_obj = chat3.last[:response]
puts "✓ Response ID from message: #{response_obj[:id]}"
puts "✓ Model: #{response_obj[:model]}"
puts "✓ Usage: #{response_obj[:usage]}"
puts "✓ Total tokens: #{response_obj[:total_tokens]}"
puts

puts "=== Core tests completed successfully! ==="
