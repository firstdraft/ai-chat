# Development Journey

This document captures the design decisions and implementation notes for the AI::Chat gem.

## Core Design Philosophy

The gem is designed with beginners in mind, specifically to:
1. Teach Ruby fundamentals (Arrays and Hashes)
2. Make AI accessible with minimal complexity
3. Provide progressive disclosure of advanced features

## Key Design Decisions

### Variable Naming in Examples
- Use single-letter variables (a, b, c...) in examples
- Makes it clear that variable names are arbitrary
- Easy to type in IRB for exploration
- Proceed alphabetically for new examples

### The `add` Method
- Chose `add` over `message` or other alternatives
- Reinforces that we're building an array
- Short and easy to type
- Makes `pp chat.messages` debugging natural

### Array of Hashes Structure
- Pedagogical value: teaches fundamental Ruby data structures
- Transparent: students can inspect exactly what they're building
- Natural progression to ActiveRecord relations in Rails apps

## Leveraging the Conversations API

### Background
OpenAI's Conversations API provides stateful conversation management, meaning the API maintains conversation context server-side. This is a significant improvement over the traditional approach of sending the full conversation history with each request.

### Our Hybrid Approach
We maintain the array of hashes for pedagogical value while leveraging the Conversations API under the hood:

```ruby
chat = AI::Chat.new
chat.user("Write a Ruby method to calculate factorial")
chat.generate!

pp chat.messages
# => [
#      {
#        role: "user",
#        content: "Write a Ruby method to calculate factorial"
#      },
#      {
#        role: "assistant",
#        content: "Here's a Ruby method to calculate factorial:\n\n```ruby\ndef factorial(n)...",
#        response: { id: "resp_abc...", model: "gpt-5-nano", ... }
#      }
#    ]
```

### Conversation Continuity
The first `generate!` call creates a conversation on the server. Subsequent calls automatically use the same `conversation_id` to maintain context:

```ruby
chat = AI::Chat.new
chat.user("My name is Alice")
chat.generate!

# The conversation_id is now set
puts chat.conversation_id  # => "conv_abc123..."

# Subsequent messages use the same conversation
chat.user("What's my name?")
chat.generate!  # Knows the name is Alice

# You can also continue in a new instance
chat2 = AI::Chat.new
chat2.conversation_id = chat.conversation_id
chat2.user("What did we discuss?")
chat2.generate!  # Has full conversation context
```

### Response Structure

After `generate!` is called, the assistant message includes a `:response` hash with metadata:

```ruby
chat.messages.last[:response]
# => {
#      id: "resp_abc123...",
#      model: "gpt-5-nano",
#      usage: {
#        input_tokens: 25,
#        output_tokens: 150,
#        total_tokens: 175
#      },
#      # ... other metadata
#    }
```

### Implementation Strategy for generate!

The `generate!` method uses the Conversations API. The first call creates a conversation, subsequent calls continue it:

```ruby
def generate!
  # Prepare messages that haven't been sent yet
  input_messages = prepare_messages_for_api

  # Create the response using conversation_id for continuity
  response = client.responses.create(
    model: @model,
    input: input_messages,
    conversation_id: @conversation_id,  # nil on first call
    # ... other options
  )

  # Store the conversation_id for subsequent calls
  @conversation_id ||= response.conversation_id
  @last_response_id = response.id

  # Extract content and add to messages
  content = extract_content_from_response(response)
  messages << {
    role: "assistant",
    content: content,
    response: response_metadata(response)
  }

  { content: content, response: response }
end
```

### Helper Methods

```ruby
class AI::Chat
  # Get the last message (user or assistant)
  def last
    messages.last
  end

  # Access token usage from last response
  def last_usage
    messages.last&.dig(:response, :usage)
  end

  # Calculate total tokens across all responses
  def total_tokens
    messages
      .filter_map { |m| m.dig(:response, :usage, :total_tokens) }
      .sum
  end

  # Retrieve conversation items from the API
  def items(order: :asc)
    client.conversations.items.list(
      conversation_id: @conversation_id,
      order: order
    )
  end
end
```

## Image Handling Design

### API Design
```ruby
# Simple single image
chat.user("What's this?", image: "photo.jpg")

# Multiple images
chat.user("Compare these", images: ["photo1.jpg", "photo2.jpg"])

# URLs work too
chat.user("Describe this", image: "https://example.com/image.png")
```

### Implementation Notes

1. **Auto-detection of input types**:
   - URLs (start with http/https)
   - File paths (read and base64 encode)
   - File-like objects (respond to :read)

2. **Error handling**:
   - Clear messages for missing files
   - Helpful hints about file locations

3. **Format conversion**:
   - Automatically convert to OpenAI's expected format
   - Handle MIME type detection
   - Base64 encoding for local files

## ActiveRecord Integration (Dropped)

### Original Plan

We originally planned extensive ActiveRecord integration:
- Re-hydrating chat instances from stored messages
- Custom serialization for Response objects
- Active Storage support for attachments

### Why We Dropped It

The Conversations API made this unnecessary. OpenAI now maintains conversation state server-side, so continuing a conversation is trivial:

```ruby
# Just store the conversation_id in your database
class ChatSession < ApplicationRecord
  # conversation_id :string
end

# To continue later, just set the conversation_id
chat = AI::Chat.new
chat.conversation_id = stored_session.conversation_id
chat.user("Continue where we left off")
chat.generate!  # Has full context from the API
```

No need to:
- Store and re-hydrate message history
- Serialize complex Response objects
- Manage conversation state locally

The API handles it all. Store a single string (`conversation_id`) and you're done.

## Implemented Features

### Web Search (Implemented)
```ruby
chat = AI::Chat.new
chat.web_search = true
chat.user("What's the latest Ruby news?")
chat.generate!  # Can search the web
```

### Session Management (Implemented via Conversations API)
```ruby
# Conversations are automatically managed
chat = AI::Chat.new
chat.user("Help me learn Ruby")
chat.generate!

# Store conversation_id, continue later
conversation_id = chat.conversation_id

# Later...
chat2 = AI::Chat.new
chat2.conversation_id = conversation_id
chat2.user("What's next?")
chat2.generate!  # Full context preserved
```

### Schema Generation (Implemented)
```ruby
# Generate JSON schemas from natural language
schema = AI::Chat.generate_schema!("A user with name, email, and age")
chat.schema = schema
```

### Proxy Support (Implemented)
```ruby
# Route through proxy server for student accounts
chat = AI::Chat.new(api_key_env_var: "PROXY_API_KEY")
chat.proxy = true
```

## Future Enhancements

### Cost Tracking
- Need to implement pricing lookup (API or hardcoded table)
- Show costs after each request
- Track cumulative costs

### Streaming Responses
```ruby
# Real-time response streaming
chat = AI::Chat.new
chat.user("Write a long story") do |chunk|
  print chunk  # Prints as generated
end
```

## Testing Strategy

1. **Unit tests** for core functionality
2. **Integration tests** with real API calls
3. **Example scripts** for manual testing

## Error Handling Philosophy

- Clear, beginner-friendly error messages
- Suggest solutions when possible
- Never expose internal complexity
- Guide users to correct usage

## Documentation Strategy

1. **README**: Simple examples progressing to advanced
2. **YARD docs**: For method documentation
3. **Examples folder**: Working examples for each feature
4. **This file**: Implementation notes and decisions
