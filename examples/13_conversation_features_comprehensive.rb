#!/usr/bin/env ruby

# This example demonstrates all conversation-related features:
# - Automatic conversation creation
# - Conversation continuity across multiple turns
# - Inspecting conversation items (programmatically and verbose)
# - Loading existing conversations

require_relative "../lib/ai-chat"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
require "amazing_print"

puts "=" * 60
puts "AI::Chat Conversation Features"
puts "=" * 60
puts

# Feature 1: Auto-creation of conversation
puts "1. Auto-creation of Conversation"
puts "-" * 60
puts "A conversation is automatically created on the first generate! call."
puts

chat = AI::Chat.new
chat.web_search = true  # Enable web search for more interesting items
puts "Before first generate!: conversation_id = #{chat.conversation_id.inspect}"

chat.user("Search for Ruby programming tutorials and tell me about one")
chat.generate!

puts "After first generate!: conversation_id = #{chat.conversation_id}"
puts "Response: #{chat.last[:content]}"
puts

# Feature 2: Conversation continuity
puts "2. Conversation Continuity"
puts "-" * 60
puts "Subsequent messages automatically use the same conversation."
puts

chat.user("What did I ask you to say?")
chat.generate!
puts "Response: #{chat.last[:content]}"
puts

# Feature 3: Programmatic access to items
puts "3. Accessing Conversation Items (Programmatically)"
puts "-" * 60
puts "Use chat.items to get conversation data for processing or display."
puts

page = chat.items
puts "Total items: #{page.data.length}"
puts "Item breakdown:"
page.data.each_with_index do |item, i|
  case item.type
  when :message
    content = begin
      item.content.first.text
    rescue
      "[complex content]"
    end
    preview = (content.length > 60) ? "#{content[0..57]}..." : content
    puts "  [#{i + 1}] #{item.type} (#{item.role}): #{preview}"
  else
    puts "  [#{i + 1}] #{item.type}"
  end
end
puts

# Feature 4: Accessing specific item types
puts "4. Accessing Specific Item Types"
puts "-" * 60
puts "You can filter items by type to access specific data like web searches."
puts

web_searches = page.data.select { |item| item.type == :web_search_call }
if web_searches.any?
  search = web_searches.first
  puts "Web search found:"
  puts "  Query: #{search.action.query}"
  puts "  Status: #{search.status}"
  if search.respond_to?(:results) && search.results
    puts "  Results: #{search.results.length} found"
    puts "  First result: #{search.results.first.title}" if search.results.first
  else
    puts "  (Results available in assistant's response)"
  end
else
  puts "No web searches in this conversation."
end
puts

# Feature 5: Order parameter for pagination
puts "5. Order Parameter (Chronological vs Reverse)"
puts "-" * 60
puts "Items default to chronological order (:asc), but you can request :desc."
puts

asc_items = chat.items
desc_items = chat.items(order: :desc)

puts "First item in chronological order:"
first = asc_items.data.first
puts "  #{first.type} #{first.role if first.respond_to?(:role)}"

puts "\nFirst item in reverse chronological order:"
first_desc = desc_items.data.first
puts "  #{first_desc.type} #{first_desc.role if first_desc.respond_to?(:role)}"
puts "\n(Reverse order is useful for pagination in long conversations)"
puts

# Feature 6: Verbose inspection
puts "6. Verbose Inspection (Terminal Output)"
puts "-" * 60
puts "Use chat.verbose for a detailed, colorized view of all conversation items."
puts
chat.verbose
puts

# Feature 7: Loading existing conversation
puts "7. Loading an Existing Conversation"
puts "-" * 60
puts "You can load a conversation_id from your database to continue a stored conversation."
puts

stored_id = chat.conversation_id
puts "Stored conversation_id: #{stored_id}"
puts

chat2 = AI::Chat.new
chat2.conversation_id = stored_id
chat2.user("What was the very first thing I asked you?")
chat2.generate!
puts "Response from loaded conversation: #{chat2.last[:content]}"
puts

puts "=" * 60
puts "All conversation features demonstrated!"
puts "=" * 60
