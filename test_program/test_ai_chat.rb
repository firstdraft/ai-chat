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

# Test with a single image
puts "\nSingle Image Support Test:"
puts "------------------------"
begin
  img_path = File.expand_path("../../spec/fixtures/test1.jpg", __FILE__)
  if File.exist?(img_path)
    i = AI::Chat.new
    i.user("What's in this image?", image: img_path)
    response = i.assistant!
    puts "Image description: #{response}"
  else
    puts "Test image not found at #{img_path}"
  end
rescue => e
  puts "Single image test error: #{e.message}"
end

# Test with multiple images
puts "\nMultiple Images Support Test:"
puts "--------------------------"
begin
  img_path1 = File.expand_path("../../spec/fixtures/test1.jpg", __FILE__)
  img_path2 = File.expand_path("../../spec/fixtures/test2.jpg", __FILE__)
  img_path3 = File.expand_path("../../spec/fixtures/test3.jpg", __FILE__)
  
  if File.exist?(img_path1) && File.exist?(img_path2) && File.exist?(img_path3)
    i = AI::Chat.new
    i.user("Compare these images and tell me what you see.", images: [img_path1, img_path2, img_path3])
    response = i.assistant!
    puts "Multiple images description: #{response}"
  else
    puts "One or more test images not found"
  end
rescue => e
  puts "Multiple images test error: #{e.message}"
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

# Reasoning Effort Test
puts "\nReasoning Effort Test:"
puts "---------------------"
begin
  r = AI::Chat.new
  r.model = "o4-mini"  # Use a reasoning model
  r.reasoning_effort = "medium"
  r.user("Write a short bash script that counts the number of unique words in a text file.")
  response = r.assistant!
  puts "Response with reasoning effort 'medium': #{response}"
rescue => e
  puts "Reasoning effort test error: #{e.message}"
end

# Reasoning Effort Validation Test
puts "\nReasoning Effort Validation Test:"
puts "-------------------------------"
begin
  r = AI::Chat.new
  puts "Setting valid reasoning effort string 'low'..."
  r.reasoning_effort = "low"
  puts "Success: reasoning_effort = #{r.reasoning_effort}"
  
  puts "Setting valid reasoning effort symbol :medium..."
  r.reasoning_effort = :medium
  puts "Success: reasoning_effort = #{r.reasoning_effort}"
  
  puts "Setting valid reasoning effort string 'high'..."
  r.reasoning_effort = "high"
  puts "Success: reasoning_effort = #{r.reasoning_effort}"
  
  puts "Setting nil reasoning effort..."
  r.reasoning_effort = nil
  puts "Success: reasoning_effort = #{r.reasoning_effort}"
  
  puts "Setting invalid reasoning effort 'extreme'..."
  r.reasoning_effort = "extreme"
  puts "This line should not be reached"
rescue ArgumentError => e
  puts "Expected error caught: #{e.message}"
end

puts "\nTests completed!"
