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
response = chat1.generate!
puts "✓ Response: #{response}"
puts "✓ Response is a String: #{response.is_a?(String)}"
puts "✓ Response Hash exists: #{chat1.last[:response].is_a?(Hash)}"
puts

# Test 2: previous_response_id functionality
puts "Test 2: previous_response_id functionality"
puts "-" * 30
chat2 = AI::Chat.new
chat2.user("My name is Alice and I live in Boston.")
chat2.generate!
response_id = chat2.previous_response_id
puts "✓ Response ID: #{chat2.last[:response][:id]}"
puts "✓ Automatically set previous_response_id: #{response_id == chat2.last[:response][:id]}"

# Create new chat with previous_response_id
chat3 = AI::Chat.new
chat3.previous_response_id = response_id
chat3.user("What is my name?")
response = chat3.generate!
puts "✓ Response: #{response}"
puts "✓ New chat remembers context: #{response.include?("Alice")}"
puts

# Test 3: Message handling
puts "Test 3: Message types and convenience methods"
puts "-" * 30
chat4 = AI::Chat.new
chat4.system("You are a helpful assistant")
chat4.user("Hello")
chat4.assistant("Hi there!")
puts "✓ Messages array: #{chat4.messages.count} messages"
puts "✓ System message: #{chat4.messages[0][:role] == "system"}"
puts "✓ User message: #{chat4.messages[1][:role] == "user"}"
puts "✓ Assistant message: #{chat4.messages[2][:role] == "assistant"}"
puts "✓ Last helper: #{chat4.last == chat4.messages.last}"
puts

# Test 4: Response details
puts "Test 4: Response details"
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
