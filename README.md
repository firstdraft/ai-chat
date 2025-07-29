# AI Chat

This gem provides a class called `AI::Chat` that is intended to make it as easy as possible to use OpenAI's cutting-edge generative AI models.

## Installation

### Gemfile way (preferred)

Add this line to your application's Gemfile:

```ruby
gem "ai-chat", "< 1.0.0"
```

And then, at a command prompt:

```
bundle install
```

### Direct way

Or, install it directly with:

```
gem install ai-chat
```

## Simplest usage

In your Ruby program:

```ruby
require "ai-chat"

# Create an instance of AI::Chat
a = AI::Chat.new

# Build up your conversation by adding messages
a.add("If the Ruby community had an official motto, what might it be?")

# See the convo so far - it's just an array of hashes!
pp a.messages
# => [{:role=>"user", :content=>"If the Ruby community had an official motto, what might it be?"}]

# Generate the next message using AI
a.generate! # => "Matz is nice and so we are nice" (or similar)

# Your array now includes the assistant's response
pp a.messages
# => [
#      {:role=>"user", :content=>"If the Ruby community had an official motto, what might it be?"},
#      {:role=>"assistant", :content=>"Matz is nice and so we are nice", :response => #<AI::Chat::Response id=resp_abc... model=gpt-4.1-nano tokens=12>}
#    ]

# Continue the conversation
a.add("What about Rails?")
a.generate! # => "Convention over configuration."
```

## Understanding the Data Structure

Every OpenAI chat is just an array of hashes. Each hash needs:
- `:role`: who's speaking ("system", "user", or "assistant")
- `:content`: what they're saying

That's it! You're building something like this:

```ruby
[
  {:role => "system", :content => "You are a helpful assistant"},
  {:role => "user", :content => "Hello!"},
  {:role => "assistant", :content => "Hi there! How can I help you today?", :response => #<AI::Chat::Response id=resp_abc... model=gpt-4.1-nano tokens=12>}
]
```

That last bit, under `:response`, is an object that represents the JSON that the OpenAI API sent back to us. It contains information about the number of tokens consumed, as well as a response ID that we can use later if we want to pick up the conversation at that point. More on that later.

## Adding Different Types of Messages

```ruby
require "ai-chat"

b = AI::Chat.new

# Add system instructions
b.add("You are a helpful assistant that talks like Shakespeare.", role: "system")

# Add a user message (role defaults to "user")
b.add("If the Ruby community had an official motto, what might it be?")

# Check what we've built
pp b.messages
# => [
#      {:role=>"system", :content=>"You are a helpful assistant that talks like Shakespeare."},
#      {:role=>"user", :content=>"If the Ruby community had an official motto, what might it be?"}
#    ]

# Generate a response
b.generate! # => "Methinks 'tis 'Ruby doth bring joy to all who craft with care'"
```

### Convenience Methods

Instead of always specifying the role, you can use these shortcuts:

```ruby
c = AI::Chat.new

# These are equivalent:
c.add("You are helpful", role: "system")
c.system("You are helpful")

# These are equivalent:
c.add("Hello there!")
c.user("Hello there!")

# These are equivalent:
c.add("Hi! How can I help?", role: "assistant")
c.assistant("Hi! How can I help?")
```

## Why This Design?

We use the `add` method (and its shortcuts) to build up an array because:

1. **It's educational**: You can see exactly what data structure you're building
2. **It's debuggable**: Use `pp a.messages` anytime to inspect your conversation
3. **It's flexible**: The same pattern works when loading existing conversations:

```ruby
# In a Rails app, you might do:
d = AI::Chat.new
d.messages = @conversation.messages  # Load existing messages
d.user("What should I do next?")     # Add a new question
d.generate!                         # Generate a response
```

## Configuration

### Model

By default, the gem uses OpenAI's `gpt-4.1-nano` model. If you want to use a different model, you can set it:

```ruby
e = AI::Chat.new
e.model = "o4-mini"
```

As of 2025-07-29, the list of chat models that you probably want to choose from are:

#### Foundation models 

- gpt-4.1-nano
- gpt-4.1-mini
- gpt-4.1

#### Reasoning models

- o4-mini
- o3

### API key

The gem by default looks for an environment variable called `OPENAI_API_KEY` and uses that if it finds it.

You can specify a different environment variable name:

```ruby
f = AI::Chat.new(api_key_env_var: "MY_OPENAI_TOKEN")
```

Or, you can pass an API key in directly:

```ruby
g = AI::Chat.new(api_key: "your-api-key-goes-here")
```

## Inspecting Your Conversation

You can call `.messages` to get an array containing the conversation so far:

```ruby
h = AI::Chat.new
h.system("You are a helpful cooking assistant")
h.user("How do I boil an egg?")
h.generate!

# See the whole conversation
pp h.messages
# => [
#      {:role=>"system", :content=>"You are a helpful cooking assistant"},
#      {:role=>"user", :content=>"How do I boil an egg?"},
#      {:role=>"assistant", :content=>"Here's how to boil an egg..."}
#    ]

# Get just the last response
h.messages.last[:content]
# => "Here's how to boil an egg..."

# Or use the convenient shortcut
h.last
# => "Here's how to boil an egg..."
```

## Structured Output

Get back Structured Output by setting the `schema` attribute (I suggest using [OpenAI's handy tool for generating the JSON Schema](https://platform.openai.com/docs/guides/structured-outputs)):

```ruby
i = AI::Chat.new

i.system("You are an expert nutritionist. The user will describe a meal. Estimate the calories, carbs, fat, and protein.")

# The schema should be a JSON string (use OpenAI's tool to generate: https://platform.openai.com/docs/guides/structured-outputs)
i.schema = '{"name": "nutrition_values","strict": true,"schema": {"type": "object","properties": {"fat": {"type": "number","description": "The amount of fat in grams."},"protein": {"type": "number","description": "The amount of protein in grams."},"carbs": {"type": "number","description": "The amount of carbohydrates in grams."},"total_calories": {"type": "number","description": "The total calories calculated based on fat, protein, and carbohydrates."}},"required": ["fat","protein","carbs","total_calories"],"additionalProperties": false}}'

i.user("1 slice of pizza")

response = i.generate!
# => {:fat=>15, :protein=>12, :carbs=>35, :total_calories=>285}

# The response is parsed JSON, not a string!
response[:total_calories]  # => 285
```

You can also provide the equivalent Ruby `Hash` rather than a `String` containing JSON.

```ruby
# Equivalent to assigning the String above
i.schema = {
  name: "nutrition_values",
  strict: true,
  schema: {
    type: "object",
    properties: {
      fat: { type: "number", description: "The amount of fat in grams." },
      protein: { type: "number", description: "The amount of protein in grams." },
      carbs: { type: "number", description: "The amount of carbohydrates in grams." },
      total_calories: { type: "number", description:
        "The total calories calculated based on fat, protein, and carbohydrates." }
    },
    required: [:fat, :protein, :carbs, :total_calories],
    additionalProperties: false
  }
}
```

The keys can be `String`s or `Symbol`s.

## Including Images

You can include images in your chat messages using the `user` method with the `image` or `images` parameter:

```ruby
j = AI::Chat.new

# Send a single image
j.user("What's in this image?", image: "path/to/local/image.jpg")
j.generate!  # => "I can see a sunset over the ocean..."

# Send multiple images
j.user("Compare these images", images: ["image1.jpg", "image2.jpg"])
j.generate!  # => "The first image shows... while the second..."

# Mix URLs and local files
j.user("What's the difference?", images: [
  "local_photo.jpg",
  "https://example.com/remote_photo.jpg"
])
j.generate!
```

The gem supports three types of image inputs:

- **URLs**: Pass an image URL starting with `http://` or `https://`
- **File paths**: Pass a string with a path to a local image file
- **File-like objects**: Pass an object that responds to `read` (like `File.open("image.jpg")` or Rails uploaded files)

## Web Search

To give the model access to real-time information from the internet, you can enable the `web_search` feature. This uses OpenAI's built-in `web_search_preview` tool.

```ruby
m = AI::Chat.new
m.web_search = true
m.user("What are the latest developments in the Ruby language?")
m.generate! # This may use web search to find current information
```

**Note:** This feature requires a model that supports the `web_search_preview` tool, such as `gpt-4o` or `gpt-4o-mini`. The gem will attempt to use a compatible model if you have `web_search` enabled.

## Building Conversations Without API Calls

You can manually add assistant messages without making API calls, which is useful when reconstructing a past conversation:

```ruby
# Create a new chat instance
k = AI::Chat.new

# Add previous messages
k.system("You are a helpful assistant who provides information about planets.")

k.user("Tell me about Mars.")
k.assistant("Mars is the fourth planet from the Sun....")

k.user("What's the atmosphere like?")
k.assistant("Mars has a very thin atmosphere compared to Earth....")

k.user("Could it support human life?")
k.assistant("Mars currently can't support human life without....")

# Now continue the conversation with an API-generated response
k.user("Are there any current missions to go there?")
response = k.generate!
puts response
```

With this, you can loop through any conversation's history (perhaps after retrieving it from your database), recreate an `AI::Chat`, and then continue it.

## Reasoning Models

When using reasoning models like `o3` or `o4-mini`, you can specify a reasoning effort level to control how much reasoning the model does before producing its final response:

```ruby
l = AI::Chat.new
l.model = "o3-mini"
l.reasoning_effort = "medium" # Can be "low", "medium", or "high"

l.user("What does this error message mean? <insert error message>")
l.generate!
```

The `reasoning_effort` parameter guides the model on how many reasoning tokens to generate before creating a response to the prompt. Options are:
- `"low"`: Favors speed and economical token usage.
- `"medium"`: (Default) Balances speed and reasoning accuracy.
- `"high"`: Favors more complete reasoning.

Setting to `nil` disables the reasoning parameter.

## Advanced: Response Details

When you call `generate!` or `generate!`, the gem stores additional information about the API response:

```ruby
t = AI::Chat.new
t.user("Hello!")
t.generate!

# Each assistant message includes a response object
pp t.messages.last
# => {
#      :role => "assistant",
#      :content => "Hello! How can I help you today?",
#      :response => #<AI::Response id=resp_abc... model=gpt-4.1-nano tokens=12>
#    }

# Access detailed information
response = t.last_response
response.id           # => "resp_abc123..."
response.model        # => "gpt-4.1-nano"
response.usage        # => {:prompt_tokens=>5, :completion_tokens=>7, :total_tokens=>12}

# Helper methods
t.last_response_id    # => "resp_abc123..."
t.last_usage          # => {:prompt_tokens=>5, :completion_tokens=>7, :total_tokens=>12}
t.total_tokens        # => 12
```

This information is useful for:

- Debugging and monitoring token usage.
- Understanding which model was actually used.
- Future features like cost tracking.

You can also, if you know a response ID, pick up an old conversation at that point in time:

```ruby
t = AI::Chat.new
t.user("Hello!")
t.generate!
old_id = t.last_response_id # => "resp_abc123..."

# Some time in the future...

u = AI::Chat.new
u.pick_up_from("resp_abc123...")
u.messages # => [
#      {:role=>"assistant", :response => #<AI::Chat::Response id=resp_abc...}
#    ]
u.user("What should we do next?")
u.generate!
```

Unless you've stored the previous messages somewhere yourself, this technique won't bring them back. But OpenAI remembers what they were, so that you can at least continue the conversation. (If you're using a reasoning model, this technique also preserves all of the model's reasoning.)

## Setting messages directly

You can use `.messages=()` to assign an `Array` of `Hashes`. Each `Hash` must have keys `:role` and `:content`, and optionally `:image` or `:images`:

```ruby
# Using the planet example with array of hashes
p = AI::Chat.new

# Set all messages at once instead of calling methods sequentially
p.messages = [
  { role: "system", content: "You are a helpful assistant who provides information about planets." },
  { role: "user", content: "Tell me about Mars." },
  { role: "assistant", content: "Mars is the fourth planet from the Sun...." },
  { role: "user", content: "What's the atmosphere like?" },
  { role: "assistant", content: "Mars has a very thin atmosphere compared to Earth...." },
  { role: "user", content: "Could it support human life?" },
  { role: "assistant", content: "Mars currently can't support human life without...." }
]

# Now continue the conversation with an API-generated response
p.user("Are there any current missions to go there?")
response = p.generate!
puts response
```

You can still include images:

```ruby
# Create a new chat instance
q = AI::Chat.new

# With images
q.messages = [
  { role: "system", content: "You are a helpful assistant." },
  { role: "user", content: "What's in this image?", image: "path/to/image.jpg" },
]

# With multiple images
q.messages = [
  { role: "system", content: "You are a helpful assistant." },
  { role: "user", content: "Compare these images", images: ["image1.jpg", "image2.jpg"] }
]
```

## Assigning `ActiveRecord::Relation`s

If your chat history is contained in an `ActiveRecord::Relation`, you can assign it directly:

```ruby
# Load from ActiveRecord
@thread = Thread.find(42)

r = AI::Chat.new
r.messages = @thread.posts.order(:created_at)
r.user("What should we discuss next?")
r.generate! # Creates a new post record, too
```

### Requirements

In order for the above to "magically" work, there are a few requirements. Your ActiveRecord model must have:

- `.role` method that returns "system", "user", or "assistant"
- `.content` method that returns the message text
- `.image` method (optional) for single images - can return URLs, file paths, or Active Storage attachments
- `.images` method (optional) for multiple images

### Custom Column Names

If your columns have different names:

```ruby
s = AI::Chat.new
s.configure_message_attributes(
  role: :message_type,     # Your column for role
  content: :message_body,  # Your column for content
  image: :attachment       # Your column/association for images
)
s.messages = @conversation.messages
```

### Saving Responses with Metadata

To preserve response metadata, add an `openai_response` column to your messages table:

```ruby
# In your migration
add_column :messages, :openai_response, :text

# In your model
class Message < ApplicationRecord
  serialize :openai_response, AI::Chat::Response
end

# Usage
@thread = Thread.find(42)

t = AI::Chat.new
t.posts = @thread.messages
t.user("Hello!")
t.generate!

# The saved message will include token usage, model info, etc.
last_message = @thread.messages.last
last_message.openai_response.usage # => {:prompt_tokens=>10, ...}
```

## Other Features Being Considered

- **Session management**: Save and restore conversations by ID
- **Streaming responses**: Real-time streaming as the AI generates its response
- **Cost tracking**: Automatic calculation and tracking of API costs

## Testing with Real API Calls

While this gem includes specs, they use mocked API responses. To test with real API calls:

1. Navigate to the test program directory: `cd demo`
2. Create a `.env` file in the test_program directory with your API credentials:
    ```
    # Your OpenAI API key
    OPENAI_API_KEY=your_openai_api_key_here
    ```
3. Install dependencies: `bundle install`
4. Run the test program: `ruby demo.rb`

This test program runs through all the major features of the gem, making real API calls to OpenAI.
