require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

# Example showcasing background mode capabilities
puts "=== AI::Chat Background Mode Examples ==="
puts
puts "1. Manual polling:"
chat = AI::Chat.new
chat.background = true
chat.user("Write a short description about a sci-fi novel about a rat in space.")
chat.generate!

message = chat.get_response

puts "#{message.is_a?(Hash) ? "✓ " : "✗"} get_response returns a Hash: #{message.class}"
puts "#{(message[:status] != :completed) ? "✓ " : "✗"} Assistant message status is: #{message[:status].inspect}"
puts "#{message[:content].empty? ? "✓ " : "✗"} Assistant message is empty: #{message[:content].inspect}"

puts
puts "manually waiting before polling again"
puts
sleep 10

message = chat.get_response

puts "#{(message[:status] == :completed) ? "✓ " : "✗"} Assistant message status is: #{message[:status].inspect}"
puts "#{(chat.messages.select { |msg| msg[:role] == "assistant" }.count == 1) ? "✓ " : "✗"} Messages contains exactly 1 Assistant message."
puts "#{(!message[:content].empty?) ? "✓ " : "✗"} Assistant message is present: #{message[:content].inspect}"

puts "\n" * 2
puts "=" * 24
puts "\n" * 2

puts "2. Automatic polling"
b = AI::Chat.new
b.background = true
b.user("Write a short description about a sci-fi novel about a rat in space.")
b.generate!

puts "\n" * 2
message = b.get_response(wait: true)
puts "\n" * 2
puts "Assistant message: #{message[:content].inspect}"
puts "Assistant message status: #{message[:status].inspect}"

puts "\n" * 4

puts "3. Timeout"
b = AI::Chat.new
b.background = true
b.user("Write a long description about a sci-fi novel about cheese in space.")
b.generate!

puts "\n" * 2
message = b.get_response(wait: true, timeout: 3)
puts "\n" * 2

puts "Cancelled message: #{message[:content].inspect}"
puts "Message status: #{message[:status].inspect}"

puts "\n" * 2
puts "=== Background Mode Examples Complete ==="
puts "\n" * 2
