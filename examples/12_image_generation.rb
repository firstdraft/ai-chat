#!/usr/bin/env ruby

# Example showcasing image generation capabilities

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "fileutils"

puts "=== AI::Chat Image Generation Examples ==="
puts

# Example 1: Basic generation + Response object access
puts "Example 1: Basic generation & Response object access"
puts "-" * 50
a = AI::Chat.new
a.image_generation = true
a.user("Draw a simple red circle")
response = a.generate!
puts "Assistant: #{response}"
puts "Images saved to: #{a.messages.last[:images]}"

# Access images through the response object
response_obj = a.messages.last[:response]
puts "Response ID: #{response_obj.id}"
puts "Images via response object: #{response_obj.images}"
puts

# Example 2: Custom image folder + Multi-turn
puts "Example 2: Custom folder & multi-turn conversation"
puts "-" * 50
b = AI::Chat.new
b.image_generation = true
b.image_folder = "./my_generated_images"
b.user("Draw a blue square")
b.generate!
puts "First image: #{b.messages.last[:images]}"

# Continue conversation without image generation
b.user("Now describe what you drew")
response = b.generate!
puts "Description: #{response}"
puts

# Example 3: Show images aren't persisted between requests
puts "Example 3: Images not persisted between requests"
puts "-" * 50
c = AI::Chat.new
c.image_generation = true
c.user("Draw a green triangle")
c.generate!
puts "Drew image: #{c.messages.last[:images]}"

# Try to reference it without image generation
c.image_generation = false
c.user("What color was the shape in the image above?")
response = c.generate!
puts "Assistant: #{response}"
puts "(Note: Model has no access to previously generated images)"
puts

# Example 4: Structured output with image generation
puts "Example 4: Structured output with image generation"
puts "-" * 50
d = AI::Chat.new
d.image_generation = true
d.schema = {
  type: "object",
  properties: {
    description: {type: "string"},
    primary_color: {type: "string"}
  },
  required: ["description", "primary_color"],
  additionalProperties: false
}

d.user("Create a simple geometric pattern and describe it")
response = d.generate!
puts "Structured response: #{response}"
puts "Images: #{d.messages.last[:images]}"
puts

puts "=== Examples Complete ==="
puts "Generated #{Dir.glob("{images,my_generated_images}/**/*.png").count} images total"
