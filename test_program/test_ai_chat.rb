#!/usr/bin/env ruby

require "bundler/setup"
require "dotenv/load"
require "ai-chat"

puts "Testing AI::Chat gem with examples from README"
puts "=============================================="

# Simplest usage example
puts "\nSimplest Usage Test:"
puts "-------------------"
x = AI::Chat.new

# Add system-level instructions
x.system("You are a helpful assistant that speaks like Shakespeare.")

# Add a user message to the chat
x.user("Hi there!")

# Get the next message from the model
begin
  response = x.assistant!
  puts "Assistant response: #{response}"
rescue => e
  puts "Error: #{e.message}"
  puts "API response: #{e.backtrace.first(3).join("\n")}"
end

# Follow-up question
x.user("What's the best pizza in Chicago?")
response = x.assistant!
puts "Assistant response: #{response}"

# Configuration example
puts "\nConfiguration Test:"
puts "-------------------"
# Using a different model
y = AI::Chat.new
y.model = "gpt-4o-mini" # Using a model that should be available
y.system("You are a helpful assistant.")
y.user("Write a haiku about programming.")
response = y.assistant!
puts "Response with model #{y.model}: #{response}"

# Structured Output example
puts "\nStructured Output Test:"
puts "-----------------------"
z = AI::Chat.new

z.system("You are an expert nutritionist. The user will describe a meal. Estimate the calories, carbs, fat, and protein.")

z.schema = '{"name": "nutrition_values","strict": true,"schema": {"type": "object","properties": {  "fat": {    "type": "number",    "description": "The amount of fat in grams."  },  "protein": {    "type": "number",    "description": "The amount of protein in grams."  },  "carbs": {    "type": "number",    "description": "The amount of carbohydrates in grams."  },  "total_calories": {    "type": "number",    "description": "The total calories calculated based on fat, protein, and carbohydrates."  }},"required": [  "fat",  "protein",  "carbs",  "total_calories"],"additionalProperties": false}}'

z.user("1 slice of pizza")
response = z.assistant!
puts "Nutrition values: #{response.inspect}"

# Test with an image (using the fixture image from the spec directory)
puts "\nImage Support Test:"
puts "------------------"
begin
  img_path = File.expand_path("../../spec/fixtures/test_image.jpg", __FILE__)
  if File.exist?(img_path)
    i = AI::Chat.new
    i.user("What's in this image?", image: img_path)
    response = i.assistant!
    puts "Image description: #{response}"
  else
    puts "Test image not found at #{img_path}"
  end
rescue => e
  puts "Image test error: #{e.message}"
  puts "#{response}"
end

# Get messages example
puts "\nMessages Test:"
puts "--------------"
m = AI::Chat.new
m.system("You are a helpful assistant.")
m.user("Hello world!")
m.assistant!
puts "Messages: #{m.messages.inspect}"

# Manual assistant message example
puts "\nManual Assistant Message Test:"
puts "-----------------------------"
a = AI::Chat.new
a.system("You are a helpful assistant.")
a.assistant("Greetings! How can I assist you today?")
a.user("Tell me a joke.")
response = a.assistant!
puts "Assistant response after manual message: #{response}"

puts "\nTests completed!"
