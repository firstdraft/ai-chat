#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"
require "json"

puts "\n=== AI::Chat Comprehensive Structured Output Tests ==="
puts

# Define a consistent task for all tests
SYSTEM_PROMPT = "Extract information about a person from the user's message."
USER_MESSAGE = "John Doe is 30 years old and works as a software engineer in San Francisco."

# Test 1: Raw schema as Ruby Hash
puts "Test 1: Raw schema as Ruby Hash"
puts "-" * 50
begin
  chat1 = AI::Chat.new
  chat1.system(SYSTEM_PROMPT)

  # Raw schema without any wrapping
  schema = {
    type: "object",
    properties: {
      name: {type: "string", description: "Person's full name"},
      age: {type: "integer", description: "Person's age"},
      occupation: {type: "string", description: "Person's job"},
      location: {type: "string", description: "Where they work"}
    },
    required: ["name", "age", "occupation", "location"],
    additionalProperties: false
  }

  chat1.schema = schema
  chat1.user(USER_MESSAGE)
  response = chat1.generate!

  puts "✓ Raw schema (Ruby Hash) worked:"
  ap response
  puts "  Name extracted: #{response[:name]}"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 2: Raw schema as JSON String
puts "Test 2: Raw schema as JSON String"
puts "-" * 50
begin
  chat2 = AI::Chat.new
  chat2.system(SYSTEM_PROMPT)

  # Same schema but as JSON string
  schema_json = <<~JSON
    {
      "type": "object",
      "properties": {
        "name": { "type": "string", "description": "Person's full name" },
        "age": { "type": "integer", "description": "Person's age" },
        "occupation": { "type": "string", "description": "Person's job" },
        "location": { "type": "string", "description": "Where they work" }
      },
      "required": ["name", "age", "occupation", "location"],
      "additionalProperties": false
    }
  JSON

  chat2.schema = schema_json
  chat2.user(USER_MESSAGE)
  response = chat2.generate!

  puts "✓ Raw schema (JSON String) worked:"
  ap response
  puts "  Age extracted: #{response[:age]}"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 3: Complex nested schema
puts "Test 3: Complex nested schema"
puts "-" * 50
begin
  chat7 = AI::Chat.new
  chat7.system("Extract company and employee information from the text.")

  complex_schema = {
    name: "company_info",
    strict: true,
    schema: {
      type: "object",
      properties: {
        company: {
          type: "object",
          properties: {
            name: {type: "string"},
            industry: {type: "string"},
            founded: {type: "integer"}
          },
          required: ["name", "industry", "founded"],
          additionalProperties: false
        },
        employees: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: {type: "string"},
              role: {type: "string"},
              years_experience: {type: "integer"}
            },
            required: ["name", "role", "years_experience"],
            additionalProperties: false
          }
        },
        total_employees: {type: "integer"}
      },
      required: ["company", "employees", "total_employees"],
      additionalProperties: false
    }
  }

  chat7.schema = complex_schema
  chat7.user("TechCorp is a software company founded in 2010. It has 50 employees including " \
             "Jane Smith who is the CEO with 15 years experience, and Bob Johnson who is " \
             "a senior developer with 8 years experience.")
  response = chat7.generate![:content]

  puts "✓ Complex nested schema worked:"
  ap response
  puts "  Company: #{response[:company][:name]}"
  puts "  Employees: #{response[:employees].map { |e| e[:name] }.join(", ")}"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Test 4: Invalid schema handling
puts "Test 4: Invalid schema handling"
puts "-" * 50
begin
  chat9 = AI::Chat.new
  chat9.schema = {invalid: "schema"}
  chat9.user("Test")
  chat9.generate!
  puts "✗ Invalid schema should have failed"
rescue => e
  puts "✓ Invalid schema correctly rejected:"
  puts "  #{e.class}: #{e.message[0..100]}..."
end
puts

puts "=== Comprehensive Structured Output tests completed ===="
