#!/usr/bin/env ruby

# Quick example showcasing key features of AI::Chat
# Run this for a fast overview of capabilities

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "\n=== AI::Chat Proxy Examples ==="
puts

puts "1. Basic conversation:"
chat = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat.proxy = true
chat.user("What's the capital of Florida?")
message = chat.generate![:content]
puts "   Message: #{message}"
puts

# 2. Structured output
puts "2. Structured output (extracting data):"
chat2 = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat2.proxy = true
chat2.system("Extract the color and animal from the message.")
chat2.schema = {
  name: "extraction",
  strict: true,
  schema: {
    type: "object",
    properties: {
      color: {type: "string"},
      animal: {type: "string"}
    },
    required: ["color", "animal"],
    additionalProperties: false
  }
}
chat2.user("I saw a red fox in the garden")
data = chat2.generate![:content]
puts "   Extracted data:"
ap data
puts

# 3. File handling
puts "3. File handling (reading text files):"
readme_path = File.expand_path("../README.md", __dir__)
chat3 = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat3.proxy = true
chat3.user("What is this gem about? (one sentence)", file: readme_path)
response = chat3.generate![:content]
puts "   #{response}"
puts

# 4. Conversation memory across instances
puts "4. Conversation memory across instances:"
chat4 = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat4.proxy = true
chat4.user("My name is Alice and I like Ruby programming")
chat4.generate!
conv_id = chat4.conversation_id
puts "conversation_id -> #{conv_id}"

# New chat instance with memory
chat5 = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat5.proxy = true
chat5.conversation_id = conv_id
chat5.user("What's my name and what do I like?")
response = chat5.generate![:content]
puts "   #{response}"
puts

# 5. Multimodal
puts "5. Mixed content types (text + image)"
puts "-" * 30
begin
  chat5 = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
  chat5.proxy = true
  chat5.system("You are an image analyst")
  chat5.user("Describe this image", image: "https://picsum.photos/200/300")
  chat5.generate!

  chat5.user("Now tell me a joke about what you saw")
  message = chat5.generate![:content]
  puts "✓ Mixed content message: #{message}"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# 6. Web search
chat6 = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat6.proxy = true
chat6.web_search = true
chat6.user("What's the latest Ruby on Rails version released?")
message = chat6.generate![:content]
puts "✓ Chat with web search: #{message[0..100]}..."
puts
# 7. Image generation
puts "Example 7: Image generation"
puts "-" * 50
chat7 = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat7.proxy = true
chat7.image_generation = true
chat7.image_folder = "./my_generated_images"
chat7.user("Draw a simple red circle")
puts "User: #{chat7.last[:content]}"
message = chat7.generate![:content]
puts "Assistant: #{message}"
image_exists = !chat7.last[:images].empty?
puts "Image generated: #{image_exists ? "✓" : "✗"}"
puts "Images saved to: #{chat7.last[:images]}"
puts

# 8. Code interpreter
puts "Example 8: Code interpreter"
puts "-" * 50

chat8 = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat8.proxy = true
chat8.code_interpreter = true
chat8.user("Plot y = 2x + 3 where x is -10 to 10.")
puts chat8.generate![:content]
puts "\n" * 5
puts "First file: #{chat8.messages.last.dig(:response, :images).empty? ? "✗" : "✓"} #{chat8.messages.last.dig(:response, :images, 0)}"
puts
puts

# 9. Background mode
puts "Example 9: Background mode"
chat9 = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat9.proxy = true
chat9.background = true
chat9.user("Write a short description about a sci-fi novel about a rat in space.")
chat9.generate!

message = chat9.get_response
puts "#{message.is_a?(Hash) ? "✓ " : "✗"} get_response returns a Hash: #{message.class}"
puts "#{(message[:status] != :completed) ? "✓ " : "✗"} Assistant message status is: #{message[:status].inspect}"
puts "#{message[:content].empty? ? "✓ " : "✗"} Assistant message is empty: #{message[:content].inspect}"
puts

puts
puts "manually waiting 15s before polling again"
puts
sleep 15

message = chat9.get_response

puts "#{(message[:status] == :completed) ? "✓ " : "✗"} Assistant message status is: #{message[:status].inspect}"
puts "#{(chat9.messages.count { |msg| msg[:role] == "assistant" } == 1) ? "✓ " : "✗"} Messages contains exactly 1 Assistant message."
puts "#{(!message[:content].empty?) ? "✓ " : "✗"} Assistant message is present: #{message[:content].inspect}"

puts "\n" * 2
puts "=" * 24
puts "\n" * 2

puts "testing auto-polling"
puts
chat9b = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat9b.background = true
chat9b.proxy = true
chat9b.user("Write a short description about a sci-fi novel about a rat in space.")
chat9b.generate!

puts "\n" * 2
message = chat9b.get_response(wait: true)
puts "\n" * 2
puts "Assistant message: #{message[:content].inspect}"
puts "Assistant message status: #{message[:status].inspect}"

puts "\n" * 4

puts "10. When an un-official API key is used and proxy is disabled:"
chat = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat.user("What's the capital of Florida?")
begin
  chat.generate!
rescue => e
  puts "✓ Raises Error: #{e.message}."
else
  puts "✗ Does not raise Error."
end

puts "\n" * 4

puts "11. When official API key is used and proxy is enabled:"
chat = AI::Chat.new
chat.proxy = true
chat.user("What's the capital of Florida?")
begin
  chat.generate!
rescue => e
  puts "✓ Raises Error: #{e.message}."
else
  puts "✗ Does not raise Error."
end
puts "\n" * 4

puts "12. Conversations:"
# Feature 1: Auto-creation of conversation
puts "a. Auto-creation of Conversation"
puts "-" * 60
puts "A conversation is automatically created on the first generate! call."
puts

chat = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat.web_search = true
chat.proxy = true
puts "Before first generate!: conversation_id = #{chat.conversation_id.inspect}"

chat.user("Search for Ruby programming tutorials and tell me about one")
chat.generate!

puts "After first generate!: conversation_id = #{chat.conversation_id}"
puts "Response: #{chat.last[:content]}"
puts

# Feature 2: Conversation continuity
puts "b. Conversation Continuity"
puts "-" * 60
puts "Subsequent messages automatically use the same conversation."
puts

chat.user("What did I ask you to say?")
chat.generate!
puts "Response: #{chat.last[:content]}"
puts

# Feature 3: Programmatic access to items
puts "c. Accessing Conversation Items (Programmatically)"
puts "-" * 60
puts "Use chat.items to get conversation data for processing or display."
puts

page = chat.items
puts "Total items: #{page.data.length}"
puts "Item breakdown:"

page.data.each_with_index do |item, i|
  case item.type
  when :message
    content = begin
      item.content.first.text
    rescue
      "[complex content]"
    end
    preview = (content.length > 60) ? "#{content[0..57]}..." : content
    puts "  [#{i + 1}] #{item.type} (#{item.role}): #{preview}"
  else
    puts "  [#{i + 1}] #{item.type}"
  end
end
puts

puts "\n" * 4

puts "13. Schema Generation:"
description = "A user profile with name (required), email (required), age (number), and bio (optional text)."
schema = AI::Chat.generate_schema!(description, api_key_env_var: "PROXY_API_KEY", proxy: true)
puts
puts schema
puts
puts "Schema can be used to generate structured output"

puts "\n" * 4

puts "=== Proxy Example Complete ==="
puts
puts "For comprehensive tests, run: bundle exec ruby examples/all.rb"
puts "For specific features, see examples/*.rb files"

puts "=== Proxy Example Complete ==="
puts
puts "For comprehensive tests, run: bundle exec ruby examples/all.rb"
puts "For specific features, see examples/*.rb files"
