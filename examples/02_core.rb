#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "=== AI::Chat Core Functionality Test ==="
puts

# Test 0: Return types
puts "Test 0: Return types"
puts "-" * 30
chat0 = AI::Chat.new
messages = chat0.system("You're a helpful assistant who talks like Spider-man.")
puts "#{messages.is_a?(Array) ? "✓ " : "✗"} AI::Chat#system returns an Array: #{messages.class}"
messages = chat0.user("What is 2 + 2?")
puts "#{messages.is_a?(Array) ? "✓ " : "✗"} AI::Chat#user returns an Array: #{messages.class}"
messages = chat0.assistant("Hey friend, the answer you're looking for is 4. Need help with anything else?")
puts "#{messages.is_a?(Array) ? "✓ " : "✗"} AI::Chat#assistant returns an Array: #{messages.class}"
puts

# Test 1: Basic conversation
puts "Test 1: Basic conversation"
puts "-" * 30
chat1 = AI::Chat.new
chat1.user("What is 2 + 2?")
message = chat1.generate!
puts "✓ Message: #{message}"
puts "✓ Message is a Hash: #{message.is_a?(Hash)}"
puts "✓ Response Hash exists: #{chat1.last[:response].is_a?(Hash)}"
puts

# Test 2: Message handling
puts "Test 2: Message types and convenience methods"
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

# Test 3: Response details
puts "Test 3: Response details"
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
