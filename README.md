# AI::Chat

This gem provides a class called `AI::Chat` that is intended to make it as easy as possible to use cutting-edge Large Language Models.

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
x = AI::Chat.new

# Add system-level instructions
x.add("You are a helpful assistant that speaks like Shakespeare.", role: "system")

# Add a user message to the chat
x.add("Hi there!", role: "user")

# Get the next message from the model
x.generate! # => "Greetings, good sir or madam! How dost thou fare on this fine day? Pray, tell me how I may be of service to thee."

# Access the messages so far
x.messages # =>
# [
#   { :role => "system", :content => "You are a helpful assistant that speaks like Shakespeare." },
#   { :role => "user", :content => "Hi there!" },
#   { :role => "assistant", :content => "Greetings, good sir or madam! How dost thou fare on this fine day? Pray, tell me how I may be of service to thee." }
# ]

# Rinse and repeat!
x.add("What's the best pizza in Chicago?", role: "user")
x.generate! # => "Ah, the fair and bustling city of Chicago, renowned for its deep-dish delight that hath captured hearts and stomachs aplenty. Amongst the many offerings of this great city, 'tis often said that Lou Malnati's and Giordano's...."
```

## Configuration

By default, the gem uses OpenAI's `gpt-4.1-nano` model. If you want to use a different model, you can set it:

```ruby
x.model = "o3"
```

The gem by default looks for an environment variable called `OPENAI_API_KEY` and uses that if it finds it.

You can specify a different environment variable name:

```ruby
x = AI::Chat.new(api_key_env_var: "MY_OPENAI_TOKEN")
```

Or, you can pass an API key in directly:

```ruby
x = AI::Chat.new(api_key: "your-api-key-goes-here")
```

## Get current messages

You can call `.messages` to get an array containing the conversation so far.

## Structured Output

Get back Structured Output by setting the `schema` attribute (I suggest using [OpenAI's handy tool for generating the JSON Schema](https://platform.openai.com/docs/guides/structured-outputs)):

```ruby
x = AI::Chat.new

x.add("You are an expert nutritionist. The user will describe a meal. Estimate the calories, carbs, fat, and protein.", role: "system")

x.schema = '{"name": "nutrition_values","strict": true,"schema": {"type": "object","properties": {  "fat": {    "type": "number",    "description": "The amount of fat in grams."  },  "protein": {    "type": "number",    "description": "The amount of protein in grams."  },  "carbs": {    "type": "number",    "description": "The amount of carbohydrates in grams."  },  "total_calories": {    "type": "number",    "description": "The total calories calculated based on fat, protein, and carbohydrates."  }},"required": [  "fat",  "protein",  "carbs",  "total_calories"],"additionalProperties": false}}'

x.add("1 slice of pizza", role: "user")

x.generate!
# => {"fat"=>15, "protein"=>5, "carbs"=>50, "total_calories"=>350}
```

## Include images

You can include images in your chat messages using the `add` method with `role: "user"` and the `image` or `images` parameter:

```ruby
# Send a single image
x.add("What's in this image?", role: "user", image: "path/to/local/image.jpg")

# Send multiple images
x.add("What are these images showing?", role: "user", images: ["path/to/image1.jpg", "https://example.com/image2.jpg"])
```

The gem supports three types of image inputs:

- URLs: Pass an image URL starting with `http://` or `https://`.
- File paths: Pass a string with a path to a local image file.
- File-like objects: Pass an object that responds to `read` (like `File.open("image.jpg")` or a Rails uploaded file).

You can send multiple images, and place them between bits of text, in a single complex user message:

```ruby
z = AI::Chat.new
z.add(
  [
    {"image" => "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Eubalaena_glacialis_with_calf.jpg/215px-Eubalaena_glacialis_with_calf.jpg"},
    {"text" => "What is in the above image? What is in the below image?"},
    {"image" => "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Elephant_Diversity.jpg/305px-Elephant_Diversity.jpg"},
    {"text" => "What are the differences between the images?"}
  ],
  role: "user"
)
z.generate!
```

Both string and symbol keys are supported for the hash items:

```ruby
z = AI::Chat.new
z.add(
  [
    {image: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Eubalaena_glacialis_with_calf.jpg/215px-Eubalaena_glacialis_with_calf.jpg"},
    {text: "What is in the above image? What is in the below image?"},
    {image: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Elephant_Diversity.jpg/305px-Elephant_Diversity.jpg"},
    {text: "What are the differences between the images?"}
  ],
  role: "user"
)
z.generate!
```

## Set assistant messages manually

You can manually add assistant messages without making API calls, which is useful when reconstructing a past conversation:

```ruby
# Create a new chat instance
y = AI::Chat.new

# Add previous messages
y.add("You are a helpful assistant who provides information about planets.", role: "system")

y.add("Tell me about Mars.", role: "user")
y.add("Mars is the fourth planet from the Sun....", role: "assistant")

y.add("What's the atmosphere like?", role: "user")
y.add("Mars has a very thin atmosphere compared to Earth....", role: "assistant")

y.add("Could it support human life?", role: "user")
y.add("Mars currently can't support human life without....", role: "assistant")

# Now continue the conversation with an API-generated response
y.add("Are there any current missions to go there?", role: "user")
response = y.generate!
puts response
```

With this, you can loop through any conversation's history (perhaps after retrieving it from your database), recreate an `AI::Chat`, and then continue it.

### Reasoning Effort

When using reasoning models like `o3` or `o4-mini`, you can specify a reasoning effort level to control how much reasoning the model does before producing its final response:

```ruby
x = AI::Chat.new
x.model = "o4-mini"
x.reasoning_effort = "medium" # Can be "low", "medium", or "high"

x.add("Write a bash script that transposes a matrix represented as '[1,2],[3,4],[5,6]'", role: "user")
x.generate!
```

The `reasoning_effort` parameter guides the model on how many reasoning tokens to generate before creating a response to the prompt. Options are:
- `"low"`: Favors speed and economical token usage
- `"medium"`: (Default) Balances speed and reasoning accuracy
- `"high"`: Favors more complete reasoning

Setting to `nil` disables the reasoning parameter.

## TODO - NOT YET IMPLEMENTED

Combined with loops and conditionals, you can do everything you need to with the above techniques. But, below are some advanced shortcuts.

### Setting messages directly

You can use `.messages=()` to assign an `Array` of `Hashes`. Each `Hash` must have keys `:role` and `:content`, and optionally `:image` or `:images`:

```ruby
# Using the planet example with array of hashes
chat = AI::Chat.new

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
chat.add("Are there any current missions to go there?", role: "user")
response = chat.generate!
puts response
```

You can still include images:

```ruby
# Create a new chat instance
chat = AI::Chat.new

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

### Assigning `ActiveRecord::Relation`s

If your chat history is contained in an `ActiveRecord::Relation`, you can assign it directly:

```ruby
chat = AI::Chat.new
chat.messages = @thread.posts.order(:created_at)
chat.generate!
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
chat = AI::Chat.new
chat.configure_message_attributes(
  role: :message_type,       # Method on the main model that returns "system", "user", or "assistant"
  content: :message_body,    # Method on the main model that returns the content of the message
  image: :image_url,         # Method on the main model that returns a URL, path, or file
  images: :attachments,      # Method on the main model that returns a collection of associated images
  source_image: :photo       # Method on the associated image that returns the URL, path, or file. Defaults to "image"
)
```

### Capture reasoning summaries

Do stuff to capture reasoning summaries.

### Store whole API response body

Add a way to access the whole API response body (rather than just the message content). Useful for keepig track of tokens, etc.

## Deprecated Methods

The following methods are deprecated and will be removed in a future version:
- `system(content)`: Use `add(content, role: "system")` instead.
- `user(content, image: nil, images: nil)`: Use `add(content, role: "user", image: image, images: images)` instead.
- `assistant(content)`: Use `add(content, role: "assistant")` instead.
- `assistant!`: Use `generate!` instead.

Please update your code to use the new API.

## Testing with Real API Calls

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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/firstdraft/ai-chat. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/firstdraft/ai-chat/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AI Chat project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/firstdraft/ai-chat/blob/main/CODE_OF_CONDUCT.md).
