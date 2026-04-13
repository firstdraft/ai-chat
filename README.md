# AI Chat

A Ruby gem that makes it easy to use OpenAI's generative AI models. Designed for learners: conversations are just arrays of hashes, so you can see exactly what's happening at every step.

## Quick Start

1. Add to your Gemfile and install:

    ```ruby
    gem "ai-chat", "< 1.0.0"
    ```

    ```
    bundle install
    ```

2. Set up your API key in a `.env` file at the root of your project:

    ```
    AICHAT_PROXY=true
    AICHAT_PROXY_KEY=your-key-from-prepend-me
    ```

    (If you have your own OpenAI account, you can skip proxy mode and set `OPENAI_API_KEY` instead.)

3. Use it:

    ```ruby
    require "dotenv/load"
    require "ai-chat"

    chat = AI::Chat.new
    chat.user("What is Ruby?")
    response = chat.generate!

    ap response
    ```

That's it. `generate!` returns the assistant's reply as a `Hash`, and `chat.messages` holds the full conversation as an `Array` of `Hash`es you can inspect, loop through, or store in a database.

## It's Just an Array of Hashes

Every conversation with an AI model is an array of hashes. Each hash has two keys:

- `:role` -- who's speaking (`"system"`, `"user"`, or `"assistant"`)
- `:content` -- what they said

Here's what a conversation looks like:

```ruby
chat = AI::Chat.new
chat.user("If Ruby had an official motto, what might it be?")
response = chat.generate!

ap response
# => {
#           :role => "assistant",
#        :content => "Matz is nice and so we are nice.",
#       :response => { id: "resp_abc...", model: "gpt-5.2", ... }
#    }

ap chat.messages
# => [
#        {
#               :role => "user",
#            :content => "If Ruby had an official motto, what might it be?"
#        },
#        {
#               :role => "assistant",
#            :content => "Matz is nice and so we are nice.",
#           :response => { id: "resp_abc...", model: "gpt-5.2", ... }
#        }
#    ]
```

`generate!` returns the assistant's message as a `Hash`. The `:response` key holds metadata from the API (token usage, response ID, model used, etc.). The user and system hashes are just `:role` and `:content`.

This design is intentional:

- **You can see what you're building.** `ap chat.messages` at any point shows the exact data structure.
- **It reinforces Ruby fundamentals.** Arrays, hashes, symbols -- you already know these.
- **It's flexible.** The same structure works when loading messages from a database:

```ruby
chat = AI::Chat.new
chat.messages = @conversation.messages  # Load from your database
chat.user("What should I do next?")
chat.generate!
```

## Adding Messages

The `user` method adds a message with `role: "user"` and `generate!` sends the conversation to the API and returns the assistant's reply:

```ruby
chat = AI::Chat.new
chat.user("Hello!")
ap chat.generate!

# Continue the conversation
chat.user("What about Rails?")
ap chat.generate!
```

You can also add system instructions (to guide the model's behavior) and manually add assistant messages (to reconstruct past conversations):

```ruby
chat = AI::Chat.new
chat.system("You are a helpful assistant that talks like Shakespeare.")
chat.user("What is Ruby?")
chat.generate!
```

Under the hood, these are shortcuts for the `add` method:

```ruby
# These are equivalent:
chat.system("You are helpful")
chat.add("You are helpful", role: "system")

# These are equivalent:
chat.user("Hello!")
chat.add("Hello!")              # role defaults to "user"

# These are equivalent:
chat.assistant("Here's what I think...")
chat.add("Here's what I think...", role: "assistant")
```

## Configuration

### Model

The gem defaults to `gpt-5.2`. You can change it:

```ruby
chat = AI::Chat.new
chat.model = "gpt-4o"
```

### API Key

By default, the gem looks for an environment variable based on whether proxy mode is on or off:

| Mode | Environment variable |
|---|---|
| Proxy on (`AICHAT_PROXY=true`) | `AICHAT_PROXY_KEY` |
| Proxy off (default) | `OPENAI_API_KEY` |

You can also specify a custom environment variable name or pass the key directly:

```ruby
# Use a different environment variable
chat = AI::Chat.new(api_key_env_var: "MY_OPENAI_TOKEN")

# Or pass the key directly
chat = AI::Chat.new(api_key: "sk-...")
```

## Proxy (Prepend.me)

If you're using a [Prepend.me](https://prepend.me/) proxy key (common in classroom settings), add these to your `.env` file:

```
AICHAT_PROXY=true
AICHAT_PROXY_KEY=your-key-from-prepend-me
```

You can also enable proxy mode in code:

```ruby
# At construction time
chat = AI::Chat.new(proxy: true)

# Or toggle it on an existing instance
chat = AI::Chat.new
chat.proxy = true
```

When proxy is enabled, API calls are routed through Prepend.me, and the gem uses `AICHAT_PROXY_KEY` instead of `OPENAI_API_KEY`.

## Web Search

Give the model access to current information from the internet:

```ruby
chat = AI::Chat.new
chat.web_search = true
chat.user("What are the latest developments in the Ruby language?")
chat.generate!
```

## Including Images

Use the `image:` or `images:` parameter to send images along with your message:

```ruby
chat = AI::Chat.new

# Single image
chat.user("What's in this image?", image: "photo.jpg")
chat.generate!

# Multiple images
chat.user("Compare these", images: ["image1.jpg", "image2.jpg"])
chat.generate!
```

You can pass local file paths, URLs (`https://...`), or file-like objects (such as `File.open(...)` or Rails uploaded files).

## Including Files

Use the `file:` or `files:` parameter to send documents:

```ruby
chat = AI::Chat.new

# Single file
chat.user("Summarize this document", file: "report.pdf")
chat.generate!

# Multiple files
chat.user("Compare these", files: ["doc1.pdf", "doc2.txt"])
chat.generate!
```

PDFs are sent as attachments. Text-based files have their content extracted and sent as text.

You can combine images and files in one message:

```ruby
chat.user("Analyze these materials",
          images: ["chart1.png", "chart2.png"],
          files: ["report.pdf", "data.csv"])
chat.generate!
```

## Structured Output

Instead of getting back a plain text response, you can ask the model to return data in a specific shape by setting a JSON schema:

```ruby
chat = AI::Chat.new
chat.system("You are an expert nutritionist. Estimate the nutritional content of the meal the user describes.")

chat.schema = {
  type: "object",
  properties: {
    fat:      { type: "number", description: "Fat in grams" },
    protein:  { type: "number", description: "Protein in grams" },
    carbs:    { type: "number", description: "Carbohydrates in grams" },
    calories: { type: "number", description: "Total calories" }
  },
  required: ["fat", "protein", "carbs", "calories"],
  additionalProperties: false
}

chat.user("1 slice of pizza")
response = chat.generate!

data = response[:content]
# => { fat: 15, protein: 12, carbs: 35, calories: 285 }

data[:calories]  # => 285
```

When a schema is set, `generate!` returns a parsed Ruby `Hash` with symbolized keys instead of a `String`.

The gem accepts several schema formats and automatically wraps them for the API. You can also pass schemas as JSON strings. See the `examples/` directory for all supported formats.

### Generating a Schema

You can use AI to generate a schema from a plain English description:

```ruby
AI::Chat.generate_schema!("A user profile with name (required), email (required), age (number), and bio (optional).")
```

This returns the JSON schema as a `String` and saves it to `schema.json`. Pass `location: false` to skip saving, or `location: "path/to/file.json"` to save elsewhere.

## Image Generation

Enable OpenAI's image generation tool to create images from descriptions:

```ruby
chat = AI::Chat.new
chat.image_generation = true
chat.user("Draw a picture of a kitten")
chat.generate!
```

Generated images are saved to `./images` by default (in timestamped subfolders like `./images/20250804T113039_resp_abc123/001.png`). You can change the folder:

```ruby
chat.image_folder = "./my_images"
```

The assistant's message will include an `:images` key with the saved file paths:

```ruby
chat.last[:images]
# => ["./images/20250804T113039_resp_abc123/001.png"]
```

AI-generated images are stored by OpenAI, so you can refine them in follow-up messages without re-sending:

```ruby
chat.user("Make it even cuter")
chat.generate!
```

## Code Interpreter

Enable the code interpreter to let the model write and execute Python code on OpenAI's servers. This is useful for math, data analysis, and generating charts:

```ruby
chat = AI::Chat.new
chat.code_interpreter = true
chat.user("Plot y = 2x^3 for x from -5 to 5")
chat.generate!
```

The model will write a Python script, execute it, and return the result (including any generated files like charts).

## Inspecting Your Conversation

You can look at the conversation at any point:

```ruby
chat = AI::Chat.new
chat.system("You are a helpful cooking assistant")
chat.user("How do I boil an egg?")
response = chat.generate!

# The return value is the assistant's reply
response[:content]
# => "Here's how to boil an egg..."

# See the whole conversation
ap chat.messages
```

## Building Conversations Without API Calls

You can manually build up a conversation without calling the API, which is useful for reconstructing a past conversation from your database:

```ruby
chat = AI::Chat.new
chat.system("You are a helpful assistant who provides information about planets.")

chat.user("Tell me about Mars.")
chat.assistant("Mars is the fourth planet from the Sun....")

chat.user("What's the atmosphere like?")
chat.assistant("Mars has a very thin atmosphere compared to Earth....")

# Now continue with an API-generated response
chat.user("Are there any current missions?")
chat.generate!
```

You can also set all messages at once with an array of hashes:

```ruby
chat = AI::Chat.new
chat.messages = [
  { role: "system", content: "You are a helpful assistant." },
  { role: "user", content: "Tell me about Mars." },
  { role: "assistant", content: "Mars is the fourth planet from the Sun...." },
  { role: "user", content: "What's the atmosphere like?" },
  { role: "assistant", content: "Mars has a very thin atmosphere...." }
]

chat.user("Could it support human life?")
chat.generate!
```

For messages with images or files, use `chat.user(..., image:, file:)` instead so the gem can build the correct multimodal structure.

## Advanced

### Reasoning Effort

Control how much reasoning the model does before responding:

```ruby
chat = AI::Chat.new
chat.reasoning_effort = "high"  # "low", "medium", or "high"

chat.user("Explain the tradeoffs between microservices and monoliths.")
chat.generate!
```

By default, `reasoning_effort` is `nil` (no reasoning parameter is sent). For `gpt-5.2`, this is equivalent to no reasoning.

### Verbosity

Control how concise or thorough the model's response is:

```ruby
chat = AI::Chat.new
chat.verbosity = :low   # :low, :medium, or :high
```

Low verbosity is good for short answers and simple code generation. High verbosity is better for thorough explanations and detailed analysis. Defaults to `:medium`.

### Background Mode

Start a response and poll for it later:

```ruby
chat = AI::Chat.new
chat.background = true
chat.user("Write a detailed analysis of Ruby's GC implementation.")
chat.generate!

# Poll until it completes
message = chat.get_response(wait: true, timeout: 600)
puts message[:content]
```

### Conversation Management

The gem automatically creates a server-side conversation on your first `generate!` call:

```ruby
chat = AI::Chat.new
chat.user("Hello")
chat.generate!

chat.conversation_id  # => "conv_abc123..."

# The model remembers context across messages
chat.user("What did I just say?")
chat.generate!
```

You can load an existing conversation:

```ruby
chat = AI::Chat.new
chat.conversation_id = @thread.conversation_id  # From your database

chat.user("Continue our discussion")
chat.generate!
```

### Response Details

Each assistant message includes an API response hash with metadata:

```ruby
chat = AI::Chat.new
chat.user("Hello!")
chat.generate!

response = chat.last[:response]
response[:id]     # => "resp_abc123..."
response[:model]  # => "gpt-5.2"
response[:usage]  # => { input_tokens: 5, output_tokens: 7, total_tokens: 12 }
```

The `last_response_id` reader always holds the most recent response ID:

```ruby
chat.last_response_id  # => "resp_abc123..."
```

### Inspecting Conversation Items

The `get_items` method fetches all conversation items from the API, including messages, tool calls, reasoning steps, and web searches:

```ruby
chat = AI::Chat.new
chat.reasoning_effort = "high"
chat.web_search = true
chat.user("Search for Ruby tutorials")
chat.generate!

# Pretty-printed in IRB/console
chat.get_items

# Iterate programmatically
chat.get_items.data.each do |item|
  case item.type
  when :message
    puts "#{item.role}: #{item.content.first.text}"
  when :web_search_call
    puts "Searched: #{item.action.query}" if item.action.respond_to?(:query)
  when :reasoning
    puts "Reasoning: #{item.summary.first.text}" if item.summary&.first
  end
end
```

### HTML Output

All display objects have a `to_html` method for rendering in ERB templates:

```erb
<%= @chat.to_html %>
<%= @chat.get_items.to_html %>
```

## Examples

The `examples/` directory contains self-contained scripts demonstrating each feature:

```bash
# Run a quick overview (~1 minute)
bundle exec ruby examples/01_quick.rb

# Run all examples
bundle exec ruby examples/all.rb

# Run any individual example
bundle exec ruby examples/02_core.rb
```

| File | Feature |
|---|---|
| `01_quick.rb` | Quick overview of key features |
| `02_core.rb` | Basic chat, messages, and responses |
| `03_multimodal.rb` | Images and basic file handling |
| `04_file_handling_comprehensive.rb` | PDFs, text files, Rails uploads |
| `05_structured_output.rb` | Basic structured output |
| `06_structured_output_comprehensive.rb` | All supported schema formats |
| `07_edge_cases.rb` | Error handling and edge cases |
| `08_additional_patterns.rb` | Direct `add` method, web search + schema |
| `09_mixed_content.rb` | Combining text and images |
| `10_image_generation.rb` | Image generation tool |
| `11_code_interpreter.rb` | Code interpreter tool |
| `12_background_mode.rb` | Background mode |
| `13_conversation_features_comprehensive.rb` | Conversation auto-creation and continuity |
| `14_schema_generation.rb` | Generate schemas from descriptions |
| `15_proxy.rb` | Proxy support |
| `16_get_items.rb` | Inspecting conversation items |
| `17_verbosity.rb` | Verbosity control |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
