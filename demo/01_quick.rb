#!/usr/bin/env ruby

# Quick demo showcasing key features of AI::Chat
# Run this for a fast overview of capabilities

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "\n=== AI::Chat Quick Demo ==="
puts "Showcasing key features in under a minute..."
puts

# 1. Basic conversation
puts "1. Basic conversation:"
chat = AI::Chat.new
chat.user("What is 2 + 2?")
response = chat.generate!
puts "   Response: #{response}"
puts

# 2. Structured output
puts "2. Structured output (extracting data):"
chat2 = AI::Chat.new
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
data = chat2.generate!
puts "   Extracted data:"
ap data
puts

# 3. File handling
puts "3. File handling (reading text files):"
readme_path = File.expand_path("../README.md", __dir__)
chat3 = AI::Chat.new
chat3.user("What is this gem about? (one sentence)", file: readme_path)
response = chat3.generate!
puts "   #{response}"
puts

# 4. Previous response ID (conversation memory)
puts "4. Conversation memory across instances:"
chat4 = AI::Chat.new
chat4.user("My name is Alice and I like Ruby programming")
chat4.generate!
response_id = chat4.previous_response_id

# New chat instance with memory
chat5 = AI::Chat.new
chat5.previous_response_id = response_id
chat5.user("What's my name and what do I like?")
response = chat5.generate!
puts "   #{response}"
puts

# 5. Model selection
puts "5. Different models:"
["gpt-4.1-nano", "gpt-4o-mini"].each do |model|
  chat = AI::Chat.new
  chat.model = model
  chat.user("Say 'Hi' in exactly 2 characters")
  response = chat.generate!
  puts "   #{model}: #{response}"
end
puts

puts "=== Quick Demo Complete ==="
puts
puts "For comprehensive tests, run: bundle exec ruby demo/all.rb"
puts "For specific features, see demo/*.rb files"
