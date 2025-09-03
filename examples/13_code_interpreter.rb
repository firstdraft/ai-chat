#!/usr/bin/env ruby

# Example showcasing code interpreter capabilities
puts "=== AI::Chat Code Interpreter Examples ==="
puts

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "fileutils"
require "amazing_print"

puts "Example 1: Basic graph generation"
puts "-" * 50

a = AI::Chat.new
a.code_interpreter = true
a.user("Plot y = 2x + 3 where x is -10 to 10.")
a.generate!
puts "\n" * 5
ap a.messages
puts "\n" * 5
puts "First file: #{a.messages.last.dig(:response, :images, 0)}"

