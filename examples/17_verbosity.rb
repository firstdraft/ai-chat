#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "\n=== AI::Chat Verbosity Tests ==="
puts

puts "1. Supports verbosity = :low"
puts "-" * 30
chat1 = AI::Chat.new
chat1.verbosity = :low
chat1.user("How high do planes typically fly?")
response = chat1.generate![:content]
puts response
puts
puts "Total characters: #{response.length}"
puts

puts "2. Supports verbosity = :medium"
puts "-" * 30
chat2 = AI::Chat.new
chat2.verbosity = :medium
chat2.user("How high do planes typically fly?")
response = chat2.generate![:content]
puts response
puts
puts "Total characters: #{response.length}"
puts

puts "3. Supports verbosity = :high"
puts "-" * 30
chat3 = AI::Chat.new
chat3.verbosity = :medium
chat3.user("How high do planes typically fly?")
response = chat3.generate![:content]
puts response
puts
puts "Total characters: #{response.length}"
puts

puts "4. Raises error for unsupported verbosity values"
puts "-" * 30
chat4 = AI::Chat.new
chat4.user("How high do planes typically fly?")
  begin
    chat4.verbosity = :extreme
  puts "✗ Failed to raise ArgumentError for invalid verbosity: #{chat4.verbosity}"
rescue ArgumentError => e
  puts "✓ Raises Argument error correctly: #{e.message}"
end
puts

puts
puts "5. Supports verbosity with Structured Outputs"
puts "-" * 30
path = "my_schemas/test.json"
File.delete(path) if File.exist?(path)
AI::Chat.generate_schema!("A user with full name (required), first_name (required), last_name (required), coolness_level (score between 0-10 representing how cool the user sounds), coolness_reasoning (the explanation of the coolness_leve)", location: path, api_key: ENV["OPENAI_API_KEY"])

chat5 = AI::Chat.new
chat5.verbosity = :low
chat5.schema_file = path
chat5.system("Extract the profile information from the user message. Describe it like a 90's robot.")
chat5.user("My name is Bryan. I like to skateboard and be cool. I'm seventeen and a quarter. You can reach me at bryan@example.com.")
puts chat5.last[:content]
puts 
begin
  response = chat5.generate![:content]
  puts "✓ Generates structured output response with verbosity"
rescue => e
  puts "✗ Failed to generate structured output response with verbosity: #{e.message}"
end
puts

puts "6. Supports verbosity = :medium for gpt-4.1-nano"
puts "-" * 30
chat6 = AI::Chat.new
chat6.model = "gpt-4.1-nano"
chat6.verbosity = :medium
chat6.user("How high do planes typically fly?")
response = chat6.generate![:content]
puts response
puts
puts "Total characters: #{response.length}"
puts

puts "7. Fails verbosity = :low for gpt-4.1-nano"
puts "-" * 30
chat7 = AI::Chat.new
chat7.model = "gpt-4.1-nano"
chat7.verbosity = :low
chat7.user("How high do planes typically fly?")
begin
  response = chat7.generate![:content]
  puts "✗ Failed to raise error when setting :low verbosity on unsupported model."
rescue OpenAI::Errors::BadRequestError => e
  puts "✓ Successfully raises error on for unsupported verbosity for older model: #{e.message}"
end
puts
