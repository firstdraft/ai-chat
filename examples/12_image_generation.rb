#!/usr/bin/env ruby

# Example showcasing image generation capabilities

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "fileutils"

puts "=== AI::Chat Image Generation Examples ==="
puts

puts "Example 1: Basic generation & Response object access"
puts "-" * 50
a = AI::Chat.new
a.image_generation = true
a.image_folder = "./my_generated_images"
user_message = a.user("Draw a simple red circle")[:content]
puts "User: #{user_message}"
message = a.generate![:content]
puts "Assistant: #{message}"
puts "Images saved to: #{a.messages.last[:images]}"

# Access images through the response object
response_obj = a.messages.last[:response]
puts "Response ID: #{response_obj[:id]}"
puts "Images via response object: #{response_obj[:images]}"
puts

puts "Example 2: Model remembers previously generated images"
puts "-" * 50
b = AI::Chat.new
b.image_generation = true
animal = ["cat", "dog", "elephant", "zebra", "crab", "parrot", "peacock", "shark"].sample
user_message = b.user("Draw a #{animal}")[:content]
puts "User: #{user_message}"
b.generate!
puts "First image: #{b.messages.last[:images]}"
user_message = b.user("Make it cuter}")[:content]
puts "User: #{user_message}"
b.generate!
puts "Second image: #{b.messages.last[:images]}"
puts

puts "Example 3: Multiturn image editing"
puts "-" * 50
c = AI::Chat.new
c.image_generation = true
image_path = File.expand_path("../spec/fixtures/thing.jpg", __dir__)
user_message = c.user("Transform this image to look like watercolor", image: image_path)[:content]
puts "User: #{user_message}"
c.generate!
puts "Assistant: #{c.messages.last[:content]}"
puts "Watercolor image: #{c.messages.last[:images]}"
c.user("Now make it black & white")
user_message = c.last[:content]
puts "User: #{user_message}"
c.generate!
puts "Assistant: #{c.messages.last[:content]}"
puts "Black and white image: #{c.messages.last[:images]}"
puts

puts "=== Image Generation Examples Complete ==="
