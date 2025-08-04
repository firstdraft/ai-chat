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
puts "User: #{a.user("Draw a simple red circle")}"
response = a.generate!
puts "Assistant: #{response}"
puts "Images saved to: #{a.messages.last[:images]}"

# Access images through the response object
response_obj = a.messages.last[:response]
puts "Response ID: #{response_obj.id}"
puts "Images via response object: #{response_obj.images}"
puts

puts "Example 2: Model remembers previously generated images"
puts "-" * 50
b = AI::Chat.new
b.image_generation = true
animal = ["cat", "dog", "elephant", "zebra", "crab", "parrot", "peacock", "shark"].sample
puts "User: #{b.user("Draw a #{animal}")}"
b.generate!
puts "First image: #{b.messages.last[:images]}"
puts "User: #{b.user("Make it cuter")}"
b.generate!
puts "Second image: #{b.messages.last[:images]}"
puts

puts "Example 3: Ghiblify - Transform an image to Studio Ghibli style"
puts "-" * 50
c = AI::Chat.new
c.image_generation = true
image_path = File.expand_path("../spec/fixtures/thing.jpg", __dir__)
puts "User: #{c.user("Transform this image into Studio Ghibli animation style", image: image_path)}"
c.generate!
puts "Assistant: #{c.messages.last[:content]}"
puts "Ghiblified image: #{c.messages.last[:images]}"
puts

puts "=== Image Generation Examples Complete ==="
