#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "\n=== AI::Chat Schema Generator - Real API Test ==="
puts

# Test the schema generator with real API calls
puts "Test: Using generated schema for structured output"
puts "-" * 50

# Define sample structure we want back from the AI
sample_nutrition = {
  food: "pizza",
  calories: 285,
  carbs: 35,
  protein: 12,
  fat: 15,
  ingredients: ["dough", "cheese", "tomato sauce"]
}

chat = AI::Chat.new
chat.system("You are an expert nutritionist. The user will describe a meal. Estimate the calories, carbs, fat, and protein.")

# Generate schema from sample structure
schema = chat.generate_schema(sample_nutrition)
puts "Generated schema from sample structure:"
ap schema

# Use the generated schema
chat.schema = schema

# Ask about a meal
chat.user("Analyze the nutrition of a cheeseburger with fries")

puts "\nWaiting for AI response with structured schema..."
begin
  response = chat.generate!
  content = response[:content]
  puts "Structured response received:"
  ap content
  puts
  puts "Response type: #{content.class}"
  puts "Has food: #{content.key?(:food)}"
  puts "Has calories: #{content.key?(:calories)}"
  puts "Has ingredients: #{content.key?(:ingredients)}"
rescue => e
  puts "Error during API call: #{e.message}"
  puts "This is expected if no API key is configured or if the schema format isn't compatible with the current API."
end

puts "\n=== Schema Generator with Real API test completed ==="