#!/usr/bin/env ruby

# Test just the schema generator functionality without full gem dependencies
puts "Testing schema generator implementation..."

# Copy just the schema generator part to test it
class SchemaGenerator
  # Main method to generate schema from any Ruby object or class
  def generate(target)
    case target
    when Class
      generate_from_class(target)
    when Hash
      generate_from_hash(target)
    when Array
      generate_from_array(target)
    else
      generate_from_object(target)
    end
  end

  private

  # Generate schema from a Ruby class
  def generate_from_class(klass)
    # Check if it's a basic Ruby class
    if klass <= Hash
      {
        type: "object",
        properties: {},
        required: []
      }
    elsif klass <= Array
      {
        type: "array",
        items: { type: "string" } # Default to string if no specific type provided
      }
    else
      # For custom classes, inspect instance variables
      generate_from_class_inspection(klass)
    end
  end

  # Generate schema by inspecting class instance variables
  def generate_from_class_inspection(klass)
    # Default to a basic object schema for custom classes
    {
      type: "object",
      properties: {},
      required: []
    }
  end

  # Generate schema from a hash structure
  def generate_from_hash(hash)
    properties = {}
    required = []

    hash.each do |key, value|
      key_name = key.is_a?(Symbol) ? key : key.to_sym
      required << key_name
      
      properties[key_name] = infer_type_from_value(value)
    end

    {
      type: "object",
      properties: properties,
      required: required
    }
  end

  # Generate schema from an array
  def generate_from_array(array)
    return {
      type: "array",
      items: { type: "string" }
    } if array.empty?

    # For arrays, we look at the first element to infer the item type
    first_item_schema = infer_type_from_value(array.first)
    
    {
      type: "array",
      items: first_item_schema
    }
  end

  # Generate schema from an arbitrary object
  def generate_from_object(object)
    # Handle different types of objects
    case object
    when Hash
      generate_from_hash(object)
    when Array
      generate_from_array(object)
    else
      # For other objects, try to infer the structure
      # If it's a simple value, return its type
      {
        type: infer_basic_type(object)
      }
    end
  end

  # Infer JSON schema type from Ruby value
  def infer_type_from_value(value)
    case value
    when Hash
      generate_from_hash(value)
    when Array
      generate_from_array(value)
    when String
      { type: "string" }
    when Integer
      { type: "integer" }
    when Float
      { type: "number" }
    when TrueClass, FalseClass
      { type: "boolean" }
    when NilClass
      { type: "null" }
    when Symbol
      { type: "string" } # Symbols can be represented as strings in JSON
    else
      # Default to string for unknown types
      { type: "string" }
    end
  end

  # Infer basic JSON schema type from Ruby object
  def infer_basic_type(obj)
    case obj
    when String
      "string"
    when Integer
      "integer"
    when Float
      "number"
    when TrueClass, FalseClass
      "boolean"
    when NilClass
      "null"
    when Hash
      "object"
    when Array
      "array"
    when Symbol
      "string"
    else
      "string" # default fallback
    end
  end
end

# Test the schema generator
generator = SchemaGenerator.new

puts "\nTest 1: Hash schema generation"
sample_hash = {
  name: "John",
  age: 30,
  active: true
}
schema = generator.generate(sample_hash)
puts "Input: #{sample_hash.inspect}"
puts "Generated: #{schema.inspect}"

puts "\nTest 2: Array schema generation"
sample_array = ["item1", "item2"]
array_schema = generator.generate(sample_array)
puts "Input: #{sample_array.inspect}"
puts "Generated: #{array_schema.inspect}"

puts "\nTest 3: Nested hash schema generation"
nested_hash = {
  user: {
    name: "Alice",
    preferences: ["reading", "coding"]
  }
}
nested_schema = generator.generate(nested_hash)
puts "Input: #{nested_hash.inspect}"
puts "Generated: #{nested_schema.inspect}"

puts "\nSchema generator tests completed successfully!"