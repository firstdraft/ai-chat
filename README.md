# OpenAI Chat

This gem provides a class called `OpenAI::Chat` that is intended to make it as easy as possible to use OpenAI's cutting-edge generative AI models.

## Installation

### Gemfile way (preferred)

Add this line to your application's Gemfile:

```ruby
gem "openai-chat", "< 1.0.0"
```

And then, at a command prompt:

```
bundle install
```

### Direct way

Or, install it directly with:

```
gem install openai-chat
```

## Simplest usage

In your Ruby program:

```ruby
require "openai/chat"

# Create an instance of OpenAI::Chat
chat = OpenAI::Chat.new

# Build up your conversation by adding messages
chat.add("If the Ruby community had an official motto, what might it be?")

# See what you've built - it's just an array of hashes!
pp chat.messages
# => [{"role"=>"user", "content"=>"If the Ruby community had an official motto, what might it be?"}]

# Generate the next message using AI
chat.generate! # => "Matz is nice and so we are nice" (or similar)

# Your array now includes the assistant's response
pp chat.messages
# => [
#      {"role"=>"user", "content"=>"If the Ruby community had an official motto, what might it be?"},
#      {"role"=>"assistant", "content"=>"Matz is nice and so we are nice"}
#    ]

# Continue the conversation
chat.add("What about Rails?")
chat.generate! # => "Convention over configuration."
```

## Understanding the Data Structure

Every OpenAI chat is just an array of hashes. Each hash needs:
- `"role"`: who's speaking ("system", "user", or "assistant")
- `"content"`: what they're saying

That's it! You're building something like this:

```ruby
[
  {"role" => "system", "content" => "You are a helpful assistant"},
  {"role" => "user", "content" => "Hello!"},
  {"role" => "assistant", "content" => "Hi there! How can I help you today?"}
]
```

## Adding Different Types of Messages

```ruby
require "openai/chat"

chat = OpenAI::Chat.new

# Add system instructions
chat.add("You are a helpful assistant that talks like Shakespeare.", role: "system")

# Add a user message (role defaults to "user")
chat.add("If the Ruby community had an official motto, what might it be?")

# Check what we've built
pp chat.messages
# => [
#      {"role"=>"system", "content"=>"You are a helpful assistant that talks like Shakespeare."},
#      {"role"=>"user", "content"=>"If the Ruby community had an official motto, what might it be?"}
#    ]

# Generate a response
chat.generate! # => "Methinks 'tis 'Ruby doth bring joy to all who craft with care'"
```

### Convenience Methods

Instead of always specifying the role, you can use these shortcuts:

```ruby
chat = OpenAI::Chat.new

# These are equivalent:
chat.add("You are helpful", role: "system")
chat.system("You are helpful")

# These are equivalent:
chat.add("Hello there!")
chat.user("Hello there!")

# These are equivalent:
chat.add("Hi! How can I help?", role: "assistant")
chat.assistant("Hi! How can I help?")
```

## Why This Design?

We use the `add` method (and its shortcuts) to build up an array because:

1. **It's educational**: You can see exactly what data structure you're building
2. **It's debuggable**: Use `pp chat.messages` anytime to inspect your conversation
3. **It's flexible**: The same pattern works when loading existing conversations:

```ruby
# In a Rails app, you might do:
chat = OpenAI::Chat.new
chat.messages = @conversation.messages  # Load existing messages
chat.user("What should I do next?")     # Add a new question
chat.assistant!                         # Generate a response
```


## Configuration

By default, the gem uses OpenAI's `gpt-4.1-nano` model. If you want to use a different model, you can set it:

```ruby
chat = OpenAI::Chat.new
chat.model = "gpt-4.1"  # More capable but costs more
chat.model = "o3-mini"  # Reasoning model for complex tasks
```

The gem by default looks for an environment variable called `OPENAI_API_KEY` and uses that if it finds it.

You can specify a different environment variable name:

```ruby
chat = OpenAI::Chat.new(api_key_env_var: "MY_OPENAI_TOKEN")
```

Or, you can pass an API key in directly:

```ruby
chat = OpenAI::Chat.new(api_key: "your-api-key-goes-here")
```

## Inspecting Your Conversation

You can call `.messages` to get an array containing the conversation so far:

```ruby
chat = OpenAI::Chat.new
chat.system("You are a helpful cooking assistant")
chat.user("How do I boil an egg?")
chat.assistant!

# See the whole conversation
pp chat.messages
# => [
#      {"role"=>"system", "content"=>"You are a helpful cooking assistant"},
#      {"role"=>"user", "content"=>"How do I boil an egg?"},
#      {"role"=>"assistant", "content"=>"Here's how to boil an egg..."}
#    ]

# Get just the last response
chat.messages.last["content"]
# => "Here's how to boil an egg..."
```

## Structured Output

Get back Structured Output by setting the `schema` attribute (I suggest using [OpenAI's handy tool for generating the JSON Schema](https://platform.openai.com/docs/guides/structured-outputs)):

```ruby
chat = OpenAI::Chat.new

chat.system("You are an expert nutritionist. The user will describe a meal. Estimate the calories, carbs, fat, and protein.")

# The schema must be a JSON string (use OpenAI's tool to generate: https://platform.openai.com/docs/guides/structured-outputs)
chat.schema = '{"name": "nutrition_values","strict": true,"schema": {"type": "object","properties": {"fat": {"type": "number","description": "The amount of fat in grams."},"protein": {"type": "number","description": "The amount of protein in grams."},"carbs": {"type": "number","description": "The amount of carbohydrates in grams."},"total_calories": {"type": "number","description": "The total calories calculated based on fat, protein, and carbohydrates."}},"required": ["fat","protein","carbs","total_calories"],"additionalProperties": false}}'

chat.user("1 slice of pizza")

response = chat.assistant!
# => {"fat"=>15, "protein"=>12, "carbs"=>35, "total_calories"=>285}

# The response is parsed JSON, not a string!
response["total_calories"]  # => 285
```

## Including Images

You can include images in your chat messages using the `user` method with the `image` or `images` parameter:

```ruby
chat = OpenAI::Chat.new

# Send a single image
chat.user("What's in this image?", image: "path/to/local/image.jpg")
chat.assistant!  # => "I can see a sunset over the ocean..."

# Send multiple images
chat.user("Compare these images", images: ["image1.jpg", "image2.jpg"])
chat.assistant!  # => "The first image shows... while the second..."

# Mix URLs and local files
chat.user("What's the difference?", images: [
  "local_photo.jpg",
  "https://example.com/remote_photo.jpg"
])
chat.assistant!
```

The gem supports three types of image inputs:

- URLs: Pass an image URL starting with `http://` or `https://`.
- File paths: Pass a string with a path to a local image file.
- File-like objects: Pass an object that responds to `read` (like `File.open("image.jpg")` or a Rails uploaded file).

You can send multiple images, and place them between bits of text, in a single complex user message:

```ruby
z = OpenAI::Chat.new
z.user(
  [
    {"image" => "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Eubalaena_glacialis_with_calf.jpg/215px-Eubalaena_glacialis_with_calf.jpg"},
    {"text" => "What is in the above image? What is in the below image?"},
    {"image" => "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Elephant_Diversity.jpg/305px-Elephant_Diversity.jpg"},
    {"text" => "What are the differences between the images?"}
  ]
)
z.assistant!
```

Both string and symbol keys are supported for the hash items:

```ruby
z = OpenAI::Chat.new
z.user(
  [
    {image: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Eubalaena_glacialis_with_calf.jpg/215px-Eubalaena_glacialis_with_calf.jpg"},
    {text: "What is in the above image? What is in the below image?"},
    {image: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Elephant_Diversity.jpg/305px-Elephant_Diversity.jpg"},
    {text: "What are the differences between the images?"}
  ]
)
z.assistant!
```

## Building Conversations Without API Calls

You can manually add assistant messages without making API calls, which is useful when reconstructing a past conversation:

```ruby
# Create a new chat instance
chat = OpenAI::Chat.new

# Add previous messages
chat.system("You are a helpful assistant who provides information about planets.")

chat.user("Tell me about Mars.")
chat.assistant("Mars is the fourth planet from the Sun....")

chat.user("What's the atmosphere like?")
chat.assistant("Mars has a very thin atmosphere compared to Earth....")

chat.user("Could it support human life?")
chat.assistant("Mars currently can't support human life without....")

# Now continue the conversation with an API-generated response
chat.user("Are there any current missions to go there?")
response = chat.assistant!
puts response
```

With this, you can loop through any conversation's history (perhaps after retrieving it from your database), recreate an `OpenAI::Chat`, and then continue it.

## Reasoning Models

When using reasoning models like `o3` or `o4-mini`, you can specify a reasoning effort level to control how much reasoning the model does before producing its final response:

```ruby
chat = OpenAI::Chat.new
chat.model = "o3-mini"
chat.reasoning_effort = "medium" # Can be "low", "medium", or "high"

chat.user("Write a bash script that transposes a matrix represented as '[1,2],[3,4],[5,6]'")
chat.assistant!
```

The `reasoning_effort` parameter guides the model on how many reasoning tokens to generate before creating a response to the prompt. Options are:
- `"low"`: Favors speed and economical token usage
- `"medium"`: (Default) Balances speed and reasoning accuracy
- `"high"`: Favors more complete reasoning

Setting to `nil` disables the reasoning parameter.

### TODO - NOT YET IMPLEMENTED

Combined with loops and conditionals, you can do everything you need to with the above techniques. But, below are some advanced shortcuts.

#### Setting messages directly

You can use `.messages=()` to assign an `Array` of `Hashes`. Each `Hash` must have keys `:role` and `:content`, and optionally `:image` or `:images`:

```ruby
# Using the planet example with array of hashes
chat = OpenAI::Chat.new

# Set all messages at once instead of calling methods sequentially
chat.messages = [
  { role: "system", content: "You are a helpful assistant who provides information about planets." },
  { role: "user", content: "Tell me about Mars." },
  { role: "assistant", content: "Mars is the fourth planet from the Sun...." },
  { role: "user", content: "What's the atmosphere like?" },
  { role: "assistant", content: "Mars has a very thin atmosphere compared to Earth...." },
  { role: "user", content: "Could it support human life?" },
  { role: "assistant", content: "Mars currently can't support human life without...." }
]

# Now continue the conversation with an API-generated response
chat.user("Are there any current missions to go there?")
response = chat.assistant!
puts response
```

You can still include images:

```ruby
# Create a new chat instance
chat = OpenAI::Chat.new

# With images
chat.messages = [
  { role: "system", content: "You are a helpful assistant." },
  { role: "user", content: "What's in this image?", image: "path/to/image.jpg" },
]

# With multiple images
chat.messages = [
  { role: "system", content: "You are a helpful assistant." },
  { role: "user", content: "Compare these images", images: ["image1.jpg", "image2.jpg"] }
]

# With complex messages
chat.messages = [
  { role: "system", content: "You are a helpful assistant." },
  { role: "user", content: 
    [
      {"image" => "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Eubalaena_glacialis_with_calf.jpg/215px-Eubalaena_glacialis_with_calf.jpg"},
      {"text" => "What is in the above image? What is in the below image?"},
      {"image" => "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Elephant_Diversity.jpg/305px-Elephant_Diversity.jpg"},
      {"text" => "What are the differences between the images?"}
    ]
  }
]
```

#### Assigning `ActiveRecord::Relation`s

If your chat history is contained in an `ActiveRecord::Relation`, you can assign it directly:

```ruby
chat = OpenAI::Chat.new
chat.messages = @thread.posts.order(:created_at)
chat.assistant!
```

In order to work:

- The record itself must respond to `.role` and `.content`.
- The record could optionally respond to `.image`, which should return:
  - A URL: an image URL starting with `http://` or `https://`.
  - A file path: a string with a path to a local image file.
  - A file-like object: an object that responds to `read` (like `File.open("image.jpg")` or a Rails uploaded file).
- The record could optionally respond to `.images`, which should return another `ActiveRecord::Relation`.
  - Each of those should respond to `.image`, similar to the above.

If your database columns or object attributes have different names, you can configure custom mappings:

```ruby
# Configure custom attribute mappings
chat = OpenAI::Chat.new
chat.configure_message_attributes(
  role: :message_type,       # Method on the main model that returns "system", "user", or "assistant"
  content: :message_body,    # Method on the main model that returns the content of the message
  image: :image_url,         # Method on the main model that returns a URL, path, or file
  images: :attachments,      # Method on the main model that returns a collection of associated images
  source_image: :photo       # Method on the associated image that returns the URL, path, or file. Defaults to "image"
)
```

#### Capture reasoning summaries

Do stuff to capture reasoning summaries.

#### Store whole API response body

Add a way to access the whole API response body (rather than just the message content). Useful for keepig track of tokens, etc.

### Testing with Real API Calls

While this gem includes specs, they use mocked API responses. To test with real API calls:

1. Navigate to the test program directory: `cd test_program`
2. Create a `.env` file in the test_program directory with your API credentials:
```
# Your OpenAI API key
OPENAI_API_KEY=your_openai_api_key_here
```
3. Install dependencies: `bundle install`
4. Run the test program: `ruby test_ai_chat.rb`

This test program runs through all the major features of the gem, making real API calls to OpenAI.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/firstdraft/openai-chat.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
