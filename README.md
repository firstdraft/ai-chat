# AI Chat

This gem provides a class called `AI::Chat` that is intended to make it as easy as possible to use OpenAI's cutting-edge generative AI models.

## Examples

This gem includes comprehensive example scripts that showcase all features and serve as both documentation and validation tests. To explore the capabilities:

### Quick Start

```bash
# Run a quick overview of key features (takes ~1 minute)
bundle exec ruby examples/01_quick.rb
```

### Run All Examples

```bash
# Run the complete test suite demonstrating all features
bundle exec ruby examples/all.rb
```

### Individual Feature Examples

The `examples/` directory contains focused examples for specific features:

- `01_quick.rb` - Quick overview of key features
- `02_core.rb` - Core functionality (basic chat, messages, responses)
- `03_configuration.rb` - Configuration options (API keys, models, reasoning effort)
- `04_multimodal.rb` - Basic file and image handling
- `05_file_handling_comprehensive.rb` - Advanced file handling (PDFs, text files, Rails uploads)
- `06_structured_output.rb` - Basic structured output with schemas
- `07_structured_output_comprehensive.rb` - All 6 supported schema formats
- `08_advanced_usage.rb` - Advanced patterns (chaining, web search)
- `09_edge_cases.rb` - Error handling and edge cases
- `10_additional_patterns.rb` - Less common usage patterns (direct add method, web search + schema, etc.)

Each example is self-contained and can be run individually:
```bash
bundle exec ruby examples/[filename]
```

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
a.generate! # => { :role => "assistant", :content => "Matz is nice and so we are nice" (or similar) }

# Your array now includes the assistant's response
pp a.messages
# => [
#      {:role=>"user", :content=>"If the Ruby community had an official motto, what might it be?"},
#      {:role=>"assistant", :content=>"Matz is nice and so we are nice", :response => { id=resp_abc... model=gpt-4.1-nano tokens=12 } }
#    ]

# Continue the conversation
a.add("What about Rails?")
a.generate! # => { :role => "assistant", :content => "Convention over configuration."} 
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
  {:role => "assistant", :content => "Hi there! How can I help you today?", :response => { id=resp_abc... model=gpt-4.1-nano tokens=12 } }
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
b.generate! # => { :role => "assistant", :content => "Methinks 'tis 'Ruby doth bring joy to all who craft with care'" }
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
h.last[:content]
# => "Here's how to boil an egg..."
```

## Web Search

To give the model access to real-time information from the internet, we enable the `web_search` feature by default. This uses OpenAI's built-in `web_search_preview` tool.

```ruby
m = AI::Chat.new
m.user("What are the latest developments in the Ruby language?")
m.generate! # This may use web search to find current information
```

**Note:** This feature requires a model that supports the `web_search_preview` tool, such as `gpt-4o` or `gpt-4o-mini`. The gem will attempt to use a compatible model if you have `web_search` enabled.

If you don't want the model to use web search, set `web_search` to `false`:

```ruby
m = AI::Chat.new
m.web_search = false
m.user("What are the latest developments in the Ruby language?")
m.generate! # This definitely won't use web search to find current information
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
data = response[:content]
# => {:fat=>15, :protein=>12, :carbs=>35, :total_calories=>285}

# The response is parsed JSON, not a string!
data[:total_calories]  # => 285
```

### Schema Formats

The gem supports multiple schema formats to accommodate different preferences and use cases. The gem will automatically wrap your schema in the correct format for the API.

#### 1. Full Schema with `format` Key (Most Explicit)
```ruby
# When you need complete control over the schema structure
i.schema = {
  format: {
    type: :json_schema,
    name: "nutrition_values",
    strict: true,
    schema: {
      type: "object",
      properties: {
        fat: { type: "number", description: "The amount of fat in grams." },
        protein: { type: "number", description: "The amount of protein in grams." }
      },
      required: ["fat", "protein"],
      additionalProperties: false
    }
  }
}
```

#### 2. Schema with `name`, `strict`, and `schema` Keys
```ruby
# The format shown in OpenAI's documentation
i.schema = {
  name: "nutrition_values",
  strict: true,
  schema: {
    type: "object",
    properties: {
      fat: { type: "number", description: "The amount of fat in grams." },
      protein: { type: "number", description: "The amount of protein in grams." }
    },
    required: [:fat, :protein],
    additionalProperties: false
  }
}
```

#### 3. Simple JSON Schema Object
```ruby
# The simplest format - just provide the schema itself
# The gem will wrap it with sensible defaults (name: "response", strict: true)
i.schema = {
  type: "object",
  properties: {
    fat: { type: "number", description: "The amount of fat in grams." },
    protein: { type: "number", description: "The amount of protein in grams." }
  },
  required: ["fat", "protein"],
  additionalProperties: false
}
```

#### 4. JSON String Formats
All the above formats also work as JSON strings:

```ruby
# As a JSON string with full format
i.schema = '{"format":{"type":"json_schema","name":"nutrition_values","strict":true,"schema":{...}}}'

# As a JSON string with name/strict/schema
i.schema = '{"name":"nutrition_values","strict":true,"schema":{...}}'

# As a simple JSON schema string
i.schema = '{"type":"object","properties":{...}}'
```

### Schema Notes

- The keys can be `String`s or `Symbol`s.
- The gem automatically converts your schema to the format expected by the API.
- When a schema is set, `generate!` returns a parsed Ruby Hash with symbolized keys, not a String.

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

## Including Files

You can include files (PDFs, text files, etc.) in your messages using the `file` or `files` parameter:

```ruby
k = AI::Chat.new

# Send a single file
k.user("Summarize this document", file: "report.pdf")
k.generate!

# Send multiple files
k.user("Compare these documents", files: ["doc1.pdf", "doc2.txt", "data.json"])
k.generate!
```

Files are handled intelligently based on their type:
- **PDFs**: Sent as file attachments for the model to analyze
- **Text files**: Content is automatically extracted and sent as text
- **Other formats**: The gem attempts to read them as text if possible

## Mixed Content (Images + Files)

You can send images and files together in a single message:

```ruby
l = AI::Chat.new

# Mix image and file in one message
l.user("Compare this photo with the document", 
       image: "photo.jpg", 
       file: "document.pdf")
l.generate!

# Mix multiple images and files
l.user("Analyze all these materials",
       images: ["chart1.png", "chart2.png"],
       files: ["report.pdf", "data.csv"])
l.generate!
```

**Note**: Images should use `image:`/`images:` parameters, while documents should use `file:`/`files:` parameters.

## Re-sending old images and files

Note: if you generate another API request using the same chat, old images and files in the conversation history will not be re-sent by default. If you really want to re-send old images and files, then you must set `previous_response_id` to `nil`:

```ruby
a = AI::Chat.new
a.user("What color is the object in this photo?", image: "thing.png")
a.generate! # => "Red"
a.user("What is the object in the photo?")
a.generate! # => { :content => "I don't see a photo", ... }

b = AI::Chat.new
b.user("What color is the object in this photo?", image: "thing.png")
b.generate! # => "Red"
b.user("What is the object in the photo?")
b.previous_response_id = nil
b.generate! # => { :content => "An apple", ... }
```

If you don't set `previous_response_id` to `nil`, the model won't have the old image(s) to work with.

## Image generation

You can enable OpenAI's image generation tool:

```ruby
a = AI::Chat.new
a.image_generation = true
a.user("Draw a picture of a kitten")
a.generate! # => { :content => "Here is your picture of a kitten:", ... }
```

By default, images are saved to `./images`. You can configure a different location:

```ruby
a = AI::Chat.new
a.image_generation = true
a.image_folder = "./my_images"
a.user("Draw a picture of a kitten")
a.generate! # => { :content => "Here is your picture of a kitten:", ... }
```

Images are saved in timestamped subfolders using ISO 8601 basic format. For example:
- `./images/20250804T11303912_resp_abc123/001.png`
- `./images/20250804T11303912_resp_abc123/002.png` (if multiple images)

The folder structure ensures images are organized chronologically and by response.

The messages array will now look like this:

```ruby
pp a.messages
# => [
#   {:role=>"user", :content=>"Draw a picture of a kitten"},
#   {:role=>"assistant", :content=>"Here is your picture of a kitten:", :images => ["./images/20250804T11303912_resp_abc123/001.png"], :response => #<Response ...>}
# ]
```

You can access the image filenames in several ways:

```ruby
# From the last message
images = a.messages.last[:images]
# => ["./images/20250804T11303912_resp_abc123/001.png"]

# From the response object
images = a.messages.last[:response].images
# => ["./images/20250804T11303912_resp_abc123/001.png"]
```

Note: Unlike with user-provided input images, OpenAI _does_ store AI-generated output images. So, if you make another API request using the same chat, previous images generated by the model in the conversation history will automatically be used — you don't have to re-send them. This allows you to easily refine an image with user input over multi-turn chats.

```ruby
a = AI::Chat.new
a.image_generation = true
a.image_folder = "./images"
a.user("Draw a picture of a kitten")
a.generate! # => { :content => "Here is a picture of a kitten:", ... }
a.user("Make it even cuter")
a.generate! # => { :content => "Here is the kitten, but even cuter:", ... }
```

## Code Interpreter

```ruby
y = AI::Chat.new
y.code_interpreter = true
y.user("Plot y = 2x*3 when x is -5 to 5.")
y.generate! # => {:content => "Here is the graph.", ... }
```

## Proxying Through prepend.me

You can proxy API calls through [prepend.me](https://prepend.me/).

```rb
chat = AI::Chat.new
chat.proxy = true
chat.user("Tell me a story")
chat.generate!
puts chat.last[:content]
# => "Once upon a time..."
```

When proxy is enabled, **you must use the API key provided by prepend.me** in place of a real OpenAI API key. Refer to [the section on API keys](#api-key) for options on how to set your key.

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
#      :response => { id=resp_abc... model=gpt-4.1-nano tokens=12 }
#    }

# Access detailed information
response = t.last[:response]
response[:id]           # => "resp_abc123..."
response[:model]        # => "gpt-4.1-nano"
response[:usage]        # => {:prompt_tokens=>5, :completion_tokens=>7, :total_tokens=>12}
```

This information is useful for:

- Debugging and monitoring token usage.
- Understanding which model was actually used.
- Future features like cost tracking.

You can also, if you know a response ID, continue an old conversation by setting the `previous_response_id`:

```ruby
t = AI::Chat.new
t.user("Hello!")
t.generate!
old_id = t.last[:response][:id] # => "resp_abc123..."

# Some time in the future...

u = AI::Chat.new
u.previous_response_id = "resp_abc123..."
u.user("What did I just say?")
u.generate! # Will have context from the previous conversation}
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

1. Create a `.env` file at the project root with your API credentials:
    ```
    # Your OpenAI API key
    OPENAI_API_KEY=your_openai_api_key_here
    ```
2. Install dependencies: `bundle install`
3. Run the examples: `bundle exec ruby examples/all.rb`

This test program runs through all the major features of the gem, making real API calls to OpenAI.
