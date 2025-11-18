#!/usr/bin/env ruby

# This example demonstrates all schema generation-related capabilities
# - JSON schema generation
# - JSON schema STDOUT format
# - JSON schema used for Structured Output

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "=" * 60
puts "AI::Chat Schema Generation Features"
puts "=" * 60
puts

# Schema Generation
puts "1. Schema Generation"
puts "-" * 60
puts
puts "Schema is indented and formatted:"
schema = AI::Chat.generate_schema!("A user profile with name (required), email (required), age (number), and bio (optional text).")
puts
puts schema
puts
puts "Schema can be used to generate structured output"
puts
chat = AI::Chat.new
chat.schema = schema
chat.system("Extract the profile information from the user message")
chat.user("My name is Bryan. I like to skateboard and be cool. I'm seventeen and a quarter. You can reach me at bryan@example.com.")
chat.generate!
ap chat.last[:content]

# Schema Generation configuration
puts "2. Schema Generation with custom environment variable"
puts "-" * 60
puts
# Test with custom env var
ENV["CUSTOM_KEY"] = ENV["OPENAI_API_KEY"]
begin
  AI::Chat.generate_schema!("A user with full name (required), first_name (required), and last_name (required).", api_key_env_var: "CUSTOM_KEY")
  puts "✓ Custom environment variable works"
rescue => e
  puts "✗ Custom environment variable failed: #{e.message}"
end
ENV.delete("CUSTOM_KEY")
puts

puts "3. Schema Generation with direct API key"
puts "-" * 60
puts
begin
  AI::Chat.generate_schema!("A user with full name (required), first_name (required), and last_name (required).", api_key: ENV["OPENAI_API_KEY"])
  puts "✓ Direct API key works"
rescue => e
  puts "✗ Direct API key failed: #{e.message}"
end
puts

puts "4. Schema Generation writes to schema.json by default"
puts "-" * 60
puts
# Remove schema file if exists
File.delete("schema.json") if File.exist?("schema.json")
AI::Chat.generate_schema!("A user with full name (required), first_name (required), and last_name (required).", api_key: ENV["OPENAI_API_KEY"])
if File.exist?("schema.json")
  puts "✓ AI::Chat.generate_schema! creates file"
else
  puts "✗ AI::Chat.generate_schema! fails to create file"
end
puts

puts "5. Schema Generation DOES NOT write to file when location: false"
puts "-" * 60
puts
# Remove schema file if exists
File.delete("schema.json") if File.exist?("schema.json")
puts AI::Chat.generate_schema!("A user with full name (required), first_name (required), and last_name (required).", location: false, api_key: ENV["OPENAI_API_KEY"])
puts
if File.exist?("schema.json")
  puts "✗ AI::Chat.generate_schema! creates file"
else
  puts "✓ AI::Chat.generate_schema! does not create file"
end
puts

puts "6. Schema Generation writes to custom file given location"
puts "-" * 60
puts
# Remove schema file if exists
path = "my_schemas/test.json"
File.delete(path) if File.exist?(path)
puts AI::Chat.generate_schema!("A user with full name (required), first_name (required), and last_name (required).", location: path, api_key: ENV["OPENAI_API_KEY"])
puts
if File.exist?(path)
  puts "✓ AI::Chat.generate_schema! creates file at #{path}"
else
  puts "✗ AI::Chat.generate_schema! does not create file at #{path}"
end
puts
