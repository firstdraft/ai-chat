#!/usr/bin/env ruby

# Quick example showcasing key features of AI::Chat
# Run this for a fast overview of capabilities

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"
def with_captured_stderr
  original_stderr = $stderr  # capture previous value of $stderr
  $stderr = StringIO.new     # assign a string buffer to $stderr
  yield                      # perform the body of the user code
  $stderr.string             # return the contents of the string buffer
ensure
  $stderr = original_stderr  # restore $stderr to its previous value
end

puts "\n=== AI::Chat Proxy Examples ==="
puts

# 1. Basic conversation
puts "1. Basic conversation:"
chat = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat.proxy = true
chat.user("What's the capital of Florida?")
message = chat.generate![:content]
puts "   Message: #{message}"
puts

# 2. Structured output
puts "2. Structured output (extracting data):"
chat2 = AI::Chat.new(api_key_env_var "PROXY_API_KEY")
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
chat3 = AI::Chat.new(api_key_env_var "PROXY_API_KEY")
chat3.proxy = true
chat3.user("What is this gem about? (one sentence)", file: readme_path)
response = chat3.generate![:content]
puts "   #{response}"
puts

# 4. Previous response ID (conversation memory)
puts "4. Conversation memory across instances:"
chat4 = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat4.proxy = true
chat4.user("My name is Alice and I like Ruby programming")
chat4.generate!
response_id = chat4.previous_response_id
puts "previous_response_id -> #{response_id}"

# New chat instance with memory
chat5 = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat5.proxy = true
chat5.previous_response_id = response_id
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
chat6.model = "gpt-4o"
chat6.web_search = true
chat6.user("What's the latest Ruby on Rails version released?")
message = chat6.generate![:content]
puts "✓ Chat with web search: #{message[0..100]}..."
puts
# 7. Image generation
puts "Example 7: Image generation is not allowed through proxy"
puts "-" * 50
chat7 = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat7.proxy = true
chat7.image_generation = true
chat7.image_folder = "./my_generated_images"
chat7.user("Draw a simple red circle")
puts "User: #{chat7.last[:content]}"
puts
generate_output = with_captured_stderr do
  chat7.generate!
end
puts "generate! exited with message?: \"#{generate_output.chomp}\""
puts

# 8. Code interpreter
puts "Example 8: Code interpreter... skipped for now"
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
puts "#{message[:status] != :completed ? "✓ " : "✗"} Assistant message status is: #{message[:status].inspect}"
puts "#{message[:content].empty? ? "✓ " : "✗"} Assistant message is empty: #{message[:content].inspect}"
puts

puts
puts "manually waiting 15s before polling again"
puts
sleep 15

message = chat9.get_response

puts "#{message[:status] == :completed ? "✓ " : "✗"} Assistant message status is: #{message[:status].inspect}"
puts "#{chat9.messages.select { |msg| msg[:role] == "assistant"}.count == 1 ? "✓ " : "✗"} Messages contains exactly 1 Assistant message."
puts "#{!message[:content].empty? ? "✓ " : "✗"} Assistant message is present: #{message[:content].inspect}"

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

puts "=== Proxy Example Complete ==="
puts
puts "For comprehensive tests, run: bundle exec ruby examples/all.rb"
puts "For specific features, see examples/*.rb files"
