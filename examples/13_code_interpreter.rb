#!/usr/bin/env ruby

puts
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
puts a.generate![:content]
puts "\n" * 5
puts "First file: #{a.messages.last.dig(:response, :images).empty? ? "✗" : "✓"} #{a.messages.last.dig(:response, :images, 0)}"

puts "Example 2: Basic math"
puts "-" * 50

b = AI::Chat.new
b.code_interpreter = true

b.system("You are a personal math tutor. When asked a math question, write and run code using the python tool to answer the question.")
b.user("Solve the equation 3x + 11 = 14.")
puts b.generate![:content]
puts "\n" * 5

