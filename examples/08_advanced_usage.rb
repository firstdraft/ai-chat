#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "\n=== AI::Chat Advanced Usage Tests ==="
puts

# Test 1: Conversation chaining and memory
puts "Test 1: Conversation chaining and memory"
puts "-" * 30
chat1 = AI::Chat.new
chat1.system("You are a math tutor. Keep responses concise.")
chat1.user("What is 10 + 15?")
message1 = chat1.generate![:content]
puts "✓ First message: #{message1}"

chat1.user("Multiply that result by 2")
message2 = chat1.generate![:content]
puts "✓ Second message: #{message2}"

chat1.user("What was the original sum I asked about?")
message3 = chat1.generate![:content]
puts "✓ Memory test: #{message3}"
puts

# Test 2: Web search capability
puts "Test 2: Web search capability"
puts "-" * 30
chat2 = AI::Chat.new
chat2.model = "gpt-4o-mini"
chat2.web_search = true
puts "Web search enabled: #{chat2.web_search}"
chat2.user("What's the current weather in San Francisco?")
begin
  message = chat2.generate![:content]
  puts "✓ Message with web search: #{message}"
rescue => e
  puts "✗ Web search error: #{e.message}"
end
puts

# Test 3: Error handling
puts "Test 3: Error handling"
puts "-" * 30

# Invalid model
begin
  chat3a = AI::Chat.new
  chat3a.model = "invalid-model-name"
  chat3a.user("Hello")
  chat3a.generate!
  puts "✗ Should have raised an error for invalid model"
rescue => e
  puts "✓ Invalid model correctly caught: #{e.class}"
end

# Invalid schema
begin
  chat3b = AI::Chat.new
  chat3b.schema = {invalid: "schema"}
  chat3b.user("Hello")
  chat3b.generate!
  puts "✗ Should have raised an error for invalid schema"
rescue => e
  puts "✓ Invalid schema correctly caught: #{e.class}"
end
puts

# Test 4: Inspect method and debugging
puts "Test 4: Inspect method and debugging"
puts "-" * 30
chat4 = AI::Chat.new
chat4.model = "gpt-4o-mini"
chat4.reasoning_effort = :low
chat4.user("Hello")
puts "✓ Inspect output:"
puts chat4.inspect
puts

# Test 5: Advanced prompt patterns
puts "Test 5: Advanced prompt patterns"
puts "-" * 30
chat5 = AI::Chat.new
chat5.system("You are a code reviewer. Analyze code and provide constructive feedback.")
chat5.user(<<~CODE)
  def fibonacci(n)
    return n if n <= 1
    fibonacci(n - 1) + fibonacci(n - 2)
  end
CODE
message = chat5.generate![:content]
puts "✓ Code review message: #{message[0..150]}..."
puts

puts "=== Advanced Usage tests completed ===="
