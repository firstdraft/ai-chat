#!/usr/bin/env ruby

require_relative "../lib/ai-chat"
require "amazing_print"

puts "\n=== AI::Chat Schema Generator Tests ==="
puts

# Test 1: Generate schema from a hash structure
puts "Test 1: Generate schema from hash structure"
puts "-" * 40
chat = AI::Chat.new

sample_data = {
  name: "John Doe",
  age: 30,
  active: true,
  scores: [85, 92, 78],
  address: {
    street: "123 Main St",
    city: "Anytown",
    zip: "12345"
  }
}

schema = chat.generate_schema(sample_data)
puts "Generated schema:"
ap schema

puts "\nUsing the generated schema for structured output:"
chat.schema = schema
puts "Schema set successfully from generated schema:"
ap chat.schema
puts

# Test 2: Generate schema from nested structures
puts "Test 2: Generate schema from nested hash with arrays"
puts "-" * 40

complex_data = {
  id: 1,
  title: "Sample Product",
  tags: ["electronics", "gadget"],
  metadata: {
    created_at: "2023-01-01T00:00:00Z",
    rating: 4.5,
    in_stock: true,
    categories: [
      { name: "Electronics", priority: 1 },
      { name: "Gadgets", priority: 2 }
    ]
  }
}

chat2 = AI::Chat.new
complex_schema = chat2.generate_schema(complex_data)
puts "Generated complex schema:"
ap complex_schema
puts

# Test 3: Generate schema from basic types
puts "Test 3: Generate schema from simple types"
puts "-" * 40

chat3 = AI::Chat.new
string_schema = chat3.generate_schema("sample string")
puts "String schema:"
ap string_schema

integer_schema = chat3.generate_schema(42)
puts "Integer schema:"
ap integer_schema

boolean_schema = chat3.generate_schema(true)
puts "Boolean schema:"
ap boolean_schema

array_schema = chat3.generate_schema(["item1", "item2", "item3"])
puts "Array schema:"
ap array_schema
puts

puts "=== Schema Generator tests completed ==="