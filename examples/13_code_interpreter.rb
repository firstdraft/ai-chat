#!/usr/bin/env ruby

# Example showcasing code interpreter capabilities
puts "=== AI::Chat Code Interpreter Examples ==="
puts

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "fileutils"
require "amazing_print"

a = AI::Chat.new
a.code_interpreter = true
a.image_folder = "./my_generated_images"
a.generate!
puts "\n" * 5
ap a.messages
puts "\n" * 5
puts "First file: #{a.messages.last.dig(:response, :images, 0)}"
