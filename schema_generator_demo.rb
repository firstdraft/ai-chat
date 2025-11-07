#!/usr/bin/env ruby

require "json"
require "bigdecimal"

# This is a demonstration showing how the schema generator works within AI::Chat
# This mimics the functionality that was added to the AI::Chat class

module AI
  class Chat
    class SchemaGenerator
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

      def generate_from_class(klass)
        if klass <= Hash
          { type: "object", properties: {}, required: [] }
        elsif klass <= Array
          { type: "array", items: { type: "string" } }
        else
          { type: "object", properties: {}, required: [] }
        end
      end

      def generate_from_hash(hash)
        properties = {}
        required = []

        hash.each do |key, value|
          key_name = key.is_a?(Symbol) ? key : key.to_sym
          required << key_name
          properties[key_name] = infer_type_from_value(value)
        end

        { type: "object", properties: properties, required: required }
      end

      def generate_from_array(array)
        return { type: "array", items: { type: "string" } } if array.empty?
        { type: "array", items: infer_type_from_value(array.first) }
      end

      def generate_from_object(object)
        case object
        when Hash
          generate_from_hash(object)
        when Array
          generate_from_array(object)
        else
          { type: infer_basic_type(object) }
        end
      end

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
        when BigDecimal
          { type: "number" }
        when TrueClass, FalseClass
          { type: "boolean" }
        when NilClass
          { type: "null" }
        when Symbol
          { type: "string" }
        else
          case value.class
          when Time, DateTime
            { type: "string", format: "date-time" }
          when Date
            { type: "string", format: "date" }
          else
            { type: "string" }
          end
        end
      end

      def infer_basic_type(obj)
        case obj
        when String then "string"
        when Integer then "integer"
        when Float, BigDecimal then "number"
        when TrueClass, FalseClass then "boolean"
        when NilClass then "null"
        when Hash then "object"
        when Array then "array"
        when Symbol then "string"
        else "string"
        end
      end
    end
  end
end

# Demonstration of the new schema generator functionality
puts "🚀 AI::Chat Schema Generator - New Feature Demonstration"
puts "=" * 60
puts

# Example 1: Generate schema from a user profile hash
puts "Example 1: Generate schema from user data structure"
puts "-" * 50
user_data = {
  id: 123,
  name: "John Doe",
  email: "john@example.com",
  age: 30,
  active: true,
  preferences: ["email", "sms"],
  balance: 125.50
}

puts "Sample data structure:"
puts JSON.pretty_generate(user_data)
puts

chat = Object.new
def chat.generate_schema(target, name: nil)
  schema_generator = AI::Chat::SchemaGenerator.new
  schema = schema_generator.generate(target)
  
  # Wrap with proper format for API
  if schema.key?(:format) || schema.key?("format")
    schema
  elsif (schema.key?(:name) || schema.key?("name")) &&
      (schema.key?(:schema) || schema.key?("schema")) &&
      (schema.key?(:strict) || schema.key?("strict"))
    { format: schema.merge(type: :json_schema) }
  else
    { format: { type: :json_schema, name: "response", schema: schema, strict: true } }
  end
end

generated_schema = chat.generate_schema(user_data)
puts "Generated JSON Schema:"
puts JSON.pretty_generate(generated_schema)
puts

# Example 2: Generate schema from nested structure
puts "Example 2: Generate schema from nested order structure"
puts "-" * 50
order_data = {
  order_id: "ORD-2025-001",
  customer: {
    name: "Jane Smith",
    address: {
      street: "123 Main St",
      city: "Anytown",
      zip: "12345"
    }
  },
  items: [
    { product_id: 101, name: "Widget A", quantity: 2, price: 19.99 },
    { product_id: 102, name: "Widget B", quantity: 1, price: 29.99 }
  ],
  total: 69.97,
  shipped: false
}

puts "Sample nested data structure:"
puts JSON.pretty_generate(order_data)
puts

generated_order_schema = chat.generate_schema(order_data)
puts "Generated JSON Schema for Order:"
puts JSON.pretty_generate(generated_order_schema)
puts

# Example 3: Usage in context
puts "Example 3: How it would be used with AI::Chat for structured output"
puts "-" * 50
puts "# Create a new chat"
puts "chat = AI::Chat.new"
puts
puts "# Generate schema from example structure"
puts "sample_order = { id: 123, name: \"Product\", quantity: 1, status: \"pending\" }"
puts "chat.generate_schema(sample_order)  # This sets the schema automatically"
puts
puts "# Now use for structured output"
puts "chat.system(\"Return order information based on user request\")"
puts "chat.user(\"What's the status of order 123?\")"
puts "# chat.generate!  # Would return structured data matching the schema"
puts

puts "✅ The schema generator is now integrated into AI::Chat!"
puts "   You can generate JSON schemas from Ruby objects without external tools."
puts
puts "✨ Key benefits:"
puts "   • Generate schemas from Ruby hashes, arrays, and objects"
puts "   • Handles nested structures automatically"
puts "   • Supports all JSON schema types (string, integer, number, boolean, object, array)"
puts "   • Integrates seamlessly with existing AI::Chat schema functionality"