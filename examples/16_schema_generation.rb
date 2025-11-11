#!/usr/bin/env ruby

# This example demonstrates all schema generation-related captabilities
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
puts "The schema is set after providing a schema_description and calling generate_schema!"
puts
chat = AI::Chat.new
chat.schema_description = "A user profile with name (required), email (required), age (number), and bio (optional text)."
chat.generate_schema!
puts "Schema set: #{!chat.schema.nil? ? "✓ " : "✗"}"
puts
puts "Schema is indented and formatted:"
puts
puts chat.schema
puts
puts "Schema can be used to generate structured output"
puts
chat.system("Extract the profile information from the user message")
chat.user("My name is Bryan. I like to skateboard and be cool. I'm seventeen and a quarter. You can reach me at bryan@example.com.")
chat.generate!
ap chat.last[:content]
