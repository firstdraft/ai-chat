#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "\n=== AI::Chat Structured Output Tests ==="
puts

# Test 1: Basic structured output
puts "Test 1: Basic structured output with Hash schema"
puts "-" * 30
chat1 = AI::Chat.new
chat1.system("Extract the color and animal from the user's message.")

# Based on README format
schema = {
  name: "extraction",
  strict: true,
  schema: {
    type: "object",
    properties: {
      color: {type: "string", description: "The color mentioned"},
      animal: {type: "string", description: "The animal mentioned"}
    },
    required: ["color", "animal"],
    additionalProperties: false
  }
}

chat1.schema = schema
puts "Schema set:"
ap chat1.schema

chat1.user("I saw a red fox today")

begin
  message = chat1.generate![:content]
  puts "✓ Message:"
  ap message
  puts "✓ Message class: #{message.class}"
  puts "✓ Extracted color: #{message[:color]}"
  puts "✓ Extracted animal: #{message[:animal]}"
rescue => e
  puts "✗ Error: #{e.message}"
  puts "  This might indicate the schema format needs adjustment"
end
puts

# Test 2: Schema as JSON string
puts "Test 2: Schema as JSON string"
puts "-" * 30
chat2 = AI::Chat.new
chat2.system("Return a number between 1 and 10")

schema_json = '{"name": "number", "strict": true, "schema": {"type": "object", "properties": {"value": {"type": "integer"}}, "required": ["value"], "additionalProperties": false}}'

chat2.schema = schema_json
puts "Schema set from JSON:"
ap chat2.schema

chat2.user("Give me a random number")

begin
  message = chat2.generate![:content]
  puts "✓ Message:"
  ap message
  puts "✓ Message class: #{message.class}"
  puts "✓ Number value: #{message[:value]}"
  puts "✓ Is integer: #{message[:value].is_a?(Integer)}"
rescue => e
  puts "✗ Error: #{e.message}"
  puts "  This might indicate the schema format needs adjustment"
end
puts

# Test 3: Nutrition example from README
puts "Test 3: Nutrition analysis example"
puts "-" * 30
chat3 = AI::Chat.new
chat3.system("You are an expert nutritionist. The user will describe a meal. Estimate the calories, carbs, fat, and protein.")

# Schema from README
nutrition_schema = {
  name: "nutrition_values",
  strict: true,
  schema: {
    type: "object",
    properties: {
      fat: {type: "number", description: "The amount of fat in grams."},
      protein: {type: "number", description: "The amount of protein in grams."},
      carbs: {type: "number", description: "The amount of carbohydrates in grams."},
      total_calories: {type: "number", description: "The total calories calculated based on fat, protein, and carbohydrates."}
    },
    required: [:fat, :protein, :carbs, :total_calories],
    additionalProperties: false
  }
}

chat3.schema = nutrition_schema
chat3.user("1 slice of pizza")

begin
  message = chat3.generate![:content]
  puts "✓ Message:"
  ap message
  puts "✓ Total calories: #{message[:total_calories]}"
  puts "✓ All values are numbers: #{message.values.all? { |v| v.is_a?(Numeric) }}"
rescue => e
  puts "✗ Error: #{e.message}"
  puts "  Error details: #{e.backtrace.first(3).join("\n  ")}"
end
puts

puts "=== Structured Output tests completed ==="
