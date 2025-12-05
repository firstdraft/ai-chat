#!/usr/bin/env ruby
# frozen_string_literal: true

# This example demonstrates how to use get_items to inspect
# all conversation items including reasoning, web searches, and tool calls.

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

chat = AI::Chat.new
chat.reasoning_effort = "high"
chat.web_search = true
chat.image_generation = true

chat.user("Search for the current stable Ruby version, then generate an image of the Ruby logo with the version number prominently displayed.")

puts "Generating response with reasoning, web search, and image generation..."
puts
response = chat.generate!

puts "=== Response ==="
puts response[:content]
puts

# Fetch all conversation items from the API
items = chat.get_items

puts "=== Conversation Items ==="
puts "Total items: #{items.data.length}"
puts

# Iterate through items and display based on type
items.data.each_with_index do |item, index|
  puts "--- Item #{index + 1}: #{item.type} ---"

  case item.type
  when :message
    puts "Role: #{item.role}"
    if item.content&.first
      content = item.content.first
      case content.type
      when :input_text
        puts "Input: #{content.text}"
      when :output_text
        text = content.text.to_s
        puts "Output: #{text[0..200]}#{"..." if text.length > 200}"
      end
    end

  when :reasoning
    if item.summary&.first
      text = item.summary.first.text.to_s
      puts "Summary: #{text[0..200]}#{"..." if text.length > 200}"
    else
      puts "(Reasoning without summary)"
    end

  when :web_search_call
    puts "Query: #{item.action.query}" if item.action.respond_to?(:query) && item.action.query
    puts "Status: #{item.status}"

  when :image_generation_call
    puts "Status: #{item.status}"
    puts "Result: Image generated" if item.result
  end

  puts
end

# Display the full items object (uses custom inspect)
puts "=== Full Items Display (IRB-style) ==="
puts items.inspect
