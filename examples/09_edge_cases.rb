#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "\n=== AI::Chat Edge Cases and Error Handling Tests ==="
puts

# Test 1: API key configuration variations
puts "Test 1: API key configuration variations"
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

  # Test direct API key
  AI::Chat.new(api_key: "direct-key-example")
  puts "✓ Direct API key accepted"

  ENV.delete("MY_CUSTOM_KEY")
rescue => e
  puts "✗ Unexpected error: #{e.message}"
end
puts

# Test 2: Model configuration edge cases
puts "Test 2: Model configuration edge cases"
puts "-" * 50
begin
  chat = AI::Chat.new

  # Valid models
  valid_models = ["gpt-4.1-nano", "gpt-4o-mini", "gpt-4o", "o1-mini"]
  valid_models.each do |model|
    chat.model = model
    puts "✓ Model '#{model}' accepted"
  end

  # Invalid model (will fail at API call, not assignment)
  chat.model = "gpt-99-ultra"
  puts "✓ Model assignment accepts any string (validation happens at API)"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 3: Reasoning effort validation
puts "Test 3: Reasoning effort validation"
puts "-" * 50
begin
  chat = AI::Chat.new
  chat.model = "o1-mini"  # Reasoning model

  # Valid values
  [:low, :medium, :high, "low", "medium", "high", nil].each do |value|
    chat.reasoning_effort = value
    puts "✓ Reasoning effort '#{value.inspect}' (#{value.class}) accepted"
  end

  # Invalid values
  ["extreme", :ultra, "invalid", 123].each do |value|
    chat.reasoning_effort = value
    puts "✗ Reasoning effort '#{value}' should have failed"
  rescue ArgumentError => e
    puts "✓ Invalid reasoning effort '#{value}' rejected: #{e.message[0..60]}..."
  end
rescue => e
  puts "✗ Unexpected error: #{e.message}"
end
puts

# Test 4: Message handling edge cases
puts "Test 4: Message handling edge cases"
puts "-" * 50
begin
  chat = AI::Chat.new

  # Empty messages
  chat.user("")
  puts "✓ Empty user message accepted"

  # Very long message
  long_message = "Hello " * 1000
  chat.user(long_message)
  puts "✓ Long message (#{long_message.length} chars) accepted"

  # Special characters
  chat.user("Special chars: 🎉 émojis © ™ • – — ¿¡ «»")
  puts "✓ Special characters and emojis accepted"

  # Newlines and formatting
  chat.user("Line 1\nLine 2\n\nLine 4\t\tTabbed")
  puts "✓ Newlines and tabs accepted"

  # Multiple system messages
  chat.system("You are helpful.")
  chat.system("You are also concise.")
  puts "✓ Multiple system messages accepted"

  # Mixed message types
  chat.system("System")
  chat.user("User")
  chat.assistant("Assistant")
  chat.user("User again")
  puts "✓ Mixed message sequence accepted"
  puts "  Total messages: #{chat.messages.length}"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 5: previous_response_id edge cases
puts "Test 5: previous_response_id edge cases"
puts "-" * 50
begin
  chat1 = AI::Chat.new

  # Using previous_response_id without any messages
  chat1.previous_response_id = "resp_nonexistent"
  chat1.user("Hello")
  chat1.generate!
  puts "✓ Nonexistent previous_response_id handled gracefully"

  # Using nil previous_response_id
  chat2 = AI::Chat.new
  chat2.previous_response_id = nil
  chat2.user("Hello")
  chat2.generate!
  puts "✓ nil previous_response_id works"

  # Chaining with previous_response_id
  id1 = chat1.previous_response_id
  chat3 = AI::Chat.new
  chat3.previous_response_id = id1
  chat3.user("Continue")
  chat3.generate!
  puts "✓ Chaining with valid previous_response_id works"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 6: File/Image parameter combinations
puts "Test 6: File/Image parameter combinations"
puts "-" * 50
begin
  chat = AI::Chat.new

  # Nil values
  chat.user("Test", image: nil)
  puts "✓ nil image parameter ignored"

  chat.user("Test", file: nil)
  puts "✓ nil file parameter ignored"

  chat.user("Test", images: nil)
  puts "✓ nil images parameter ignored"

  chat.user("Test", files: nil)
  puts "✓ nil files parameter ignored"

  # Empty arrays
  chat.user("Test", images: [])
  puts "✓ Empty images array handled"

  chat.user("Test", files: [])
  puts "✓ Empty files array handled"

  # Mixed parameters (only one should be used)
  begin
    chat.user("Test", image: "pic.jpg", file: "doc.pdf")
    puts "ℹ️  Multiple file parameters accepted (image takes precedence)"
  rescue => e
    puts "ℹ️  Multiple file parameters: #{e.message}"
  end
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 7: Schema edge cases
puts "Test 7: Schema edge cases"
puts "-" * 50
begin
  chat = AI::Chat.new

  # Setting schema to nil
  chat.schema = {name: "test", strict: true, schema: {type: "object"}}
  puts "✓ Schema set"

  # Can't directly set schema to nil after it's set (no setter for nil)
  # This is a design decision - once schema is set, it stays

  # Empty schema
  begin
    chat2 = AI::Chat.new
    chat2.schema = {}
    chat2.user("Test")
    chat2.generate!
    puts "✗ Empty schema should probably fail"
  rescue => e
    puts "✓ Empty schema handled: #{e.message[0..80]}..."
  end

  # Invalid JSON string
  begin
    chat3 = AI::Chat.new
    chat3.schema = "{ invalid json }"
    puts "✗ Invalid JSON should have failed"
  rescue => e
    puts "✓ Invalid JSON correctly rejected: #{e.message}"
  end
rescue => e
  puts "✗ Unexpected error: #{e.message}"
end
puts

# Test 8: Web search edge cases
puts "Test 8: Web search edge cases"
puts "-" * 50
begin
  chat = AI::Chat.new

  # Web search with incompatible model
  chat.model = "gpt-4.1-nano"  # May not support web search
  chat.web_search = true
  puts "✓ Web search flag accepted (API will validate model compatibility)"

  # Toggle web search
  chat.web_search = false
  puts "✓ Web search can be toggled off"

  chat.web_search = true
  puts "✓ Web search can be toggled back on"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 9: Inspect and introspection
puts "Test 9: Inspect and introspection"
puts "-" * 50
begin
  chat = AI::Chat.new
  chat.model = "gpt-4o-mini"
  chat.reasoning_effort = :low
  chat.web_search = true
  chat.schema = {type: "object"}
  chat.previous_response_id = "resp_123"
  chat.system("System message")
  chat.user("User message")

  # Test inspect
  inspect_output = chat.inspect
  puts "✓ Inspect output includes:"
  puts "  - Class name: #{inspect_output.include?("AI::Chat")}"
  puts "  - Messages: #{inspect_output.include?("@messages=")}"
  puts "  - Model: #{inspect_output.include?("@model=")}"
  puts "  - Schema: #{inspect_output.include?("@schema=")}"
  puts "  - Reasoning: #{inspect_output.include?("@reasoning_effort=")}"

  # Test last helper
  last_msg = chat.last
  puts "✓ Last message helper: #{last_msg[:role]} - #{last_msg[:content][0..20]}..."

  # Test messages access
  puts "✓ Direct messages access: #{chat.messages.length} messages"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

puts "=== Edge Cases and Error Handling tests completed ===="
