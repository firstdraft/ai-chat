# Development Journey

This document captures the design decisions and implementation notes for the OpenAI::Chat gem.

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

## Leveraging the Responses API

### Background
OpenAI's Responses API provides stateful conversation management, meaning the API maintains conversation context server-side. This is a significant improvement over the traditional approach of sending the full conversation history with each request.

### Our Hybrid Approach
We maintain the array of hashes for pedagogical value while leveraging the Responses API under the hood:

```ruby
a = OpenAI::Chat.new
a.user("Write a Ruby method to calculate factorial")
a.assistant!

pp a.messages
# => [
#      {
#        "role" => "user",
#        "content" => "Write a Ruby method to calculate factorial"
#      },
#      {
#        "role" => "assistant",
#        "content" => "Here's a Ruby method to calculate factorial:\n\n```ruby\ndef factorial(n)...",
#        "response" => #<Response id=resp_abc... model=gpt-4.1-nano tokens=135>
#      }
#    ]
```

### Custom Response Class

```ruby
module OpenAI
  class Chat
    class Response
      attr_reader :id, :model, :created_at, :usage, :raw_response

      def initialize(raw_response)
        @raw_response = raw_response
        @id = raw_response.id
        @model = raw_response.model
        @created_at = Time.at(raw_response.created)
        @usage = {
          "prompt_tokens" => raw_response.usage.prompt_tokens,
          "completion_tokens" => raw_response.usage.completion_tokens,
          "total_tokens" => raw_response.usage.total_tokens,
          "reasoning_tokens" => raw_response.usage.reasoning_tokens
        }
      end

      # Clean output for beginners
      def to_s
        "#<Response id=#{id[0..7]}... model=#{model} tokens=#{usage['total_tokens']}>"
      end

      def inspect
        "#<OpenAI::Chat::Response:0x#{object_id.to_s(16)} " \
        "id=\"#{id}\", " \
        "model=\"#{model}\", " \
        "tokens=#{usage['total_tokens']}>"
      end

      # Future feature - once we have pricing data
      def cost
        # TODO: Implement based on model and token usage
        nil
      end
    end
  end
end
```

### Implementation Strategy for assistant!

```ruby
def assistant!
  # If we have a previous assistant response, use its ID for context
  previous_response_id = messages.reverse.find { |m| m["role"] == "assistant" }&.dig("response", "id")
  
  if previous_response_id
    # Continue the conversation with preserved context
    response = client.responses.create(
      model: @model,
      input: messages.last["content"],
      previous_response_id: previous_response_id,
      reasoning_effort: @reasoning_effort
    )
  else
    # New conversation - need to include full context
    response = client.responses.create(
      model: @model,
      input: build_input_from_messages,
      reasoning_effort: @reasoning_effort
    )
  end
  
  # Extract the text content
  content = extract_content_from_response(response)
  
  # Add to messages with response object
  messages << {
    "role" => "assistant",
    "content" => content,
    "response" => Response.new(response)
  }
  
  content
end
```

### Helper Methods

```ruby
class OpenAI::Chat
  def last_response
    messages.reverse.find { |m| m["response"] }&.dig("response")
  end

  def last_response_id
    last_response&.id
  end

  def last_usage
    last_response&.usage
  end

  def total_tokens
    messages
      .filter_map { |m| m["response"]&.usage&.fetch("total_tokens", 0) }
      .sum
  end

  # Future methods once we have pricing
  def last_cost
    last_response&.cost
  end

  def total_cost
    messages
      .filter_map { |m| m["response"]&.cost }
      .sum
  end
end
```

## Image Handling Design

### API Design
```ruby
# Simple single image
a.user("What's this?", image: "photo.jpg")

# Multiple images
a.user("Compare these", images: ["photo1.jpg", "photo2.jpg"])

# Complex interwoven content
a.user([
  {"text" => "What is in the above image?"},
  {"image" => "whale.jpg"},
  {"text" => "What is in the below image?"},
  {"image" => "elephant.jpg"}
])
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

## ActiveRecord Integration

### Simplified Approach

Based on feedback, we're simplifying the ActiveRecord integration:

1. **No complex interwoven messages** - Keep the image API simple
2. **Automatic Active Storage handling** - Detect and handle Rails attachments
3. **Response persistence** - Use ActiveRecord serialization for Response objects
4. **No streaming from database** - Users handle their own pagination

### Implementation Details

```ruby
class OpenAI::Chat
  def self.from_active_record(relation, **options)
    new(**options).tap do |chat|
      chat.messages = relation
    end
  end
  
  def save_last_response_to(relation, **options)
    options = {
      role_column: :role,
      content_column: :content,
      response_column: :openai_response
    }.merge(options)
    
    relation.create!(
      options[:role_column] => "assistant",
      options[:content_column] => messages.last["content"],
      options[:response_column] => last_response
    )
  end
end
```

### Response Serialization

```ruby
class OpenAI::Chat::Response
  # For ActiveRecord serialize
  def self.load(data)
    return nil if data.nil?
    # Reconstruct from stored hash
    new(OpenStruct.new(data))
  end
  
  def self.dump(obj)
    return nil if obj.nil?
    {
      'id' => obj.id,
      'model' => obj.model,
      'created' => obj.created_at.to_i,
      'usage' => obj.usage
    }
  end
end
```

### Active Storage Support

```ruby
def process_image(image_input)
  case image_input
  when /^https?:\/\//
    # URL - use as-is
    image_input
  when ActiveStorage::Attached::One
    # Rails Active Storage single attachment
    process_active_storage_attachment(image_input)
  when ActiveStorage::Blob
    # Direct blob reference
    rails_blob_url(image_input)
  when String
    # File path - read and encode
    encode_local_file(image_input)
  when ->(obj) { obj.respond_to?(:read) }
    # File-like object
    encode_file_object(image_input)
  end
end
```

## Future Enhancements

### Cost Tracking
- Need to implement pricing lookup (API or hardcoded table)
- Show costs after each request
- Track cumulative costs

### Web Search Integration
```ruby
b = OpenAI::Chat.new
b.enable_web_search!
b.user("What's the latest Ruby news?")
b.assistant! # Can search the web
```

### Session Management
```ruby
# Save/load conversations
c = OpenAI::Chat.new
c.user("Help me learn Ruby")
c.assistant!
session_id = c.save!

# Later...
d = OpenAI::Chat.load(session_id)
d.user("What's next?")
```

### Streaming Responses
```ruby
# Real-time response streaming
e = OpenAI::Chat.new
e.user("Write a long story") do |chunk|
  print chunk # Prints as generated
end
```

## Testing Strategy

1. **Unit tests** for core functionality
2. **Integration tests** with mocked API responses
3. **Example scripts** for manual testing
4. **ActiveRecord integration tests** with dummy models

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