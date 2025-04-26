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
x.system("You are a helpful assistant that speaks like Shakespeare.")

# Add a user message to the chat
x.user("Hi there!")

# Get the next message from the model
x.assistant!
# => "Greetings, good sir or madam! How dost thou fare on this fine day? Pray, tell me how I may be of service to thee."

# Rinse and repeat
x.user("What's the best pizza in Chicago?")
x.assistant!
# => "Ah, the fair and bustling city of Chicago, renowned for its deep-dish delight that hath captured hearts and stomachs aplenty. Amongst the many offerings of this great city, 'tis often said that Lou Malnati's and Giordano's...."
```

## Configuration

By default, the gem uses OpenAI's `gpt-4.1-mini` model. If you want to use a different model, you can set it:

```ruby
x.model = "o3"
```

The gem by default looks for an environment variable called `OPENAI_API_KEY` and uses that if it finds it.

You can specify a different environment variable name:

```ruby
x = AI::Chat.new(api_key_env_var: "OPENAI_TOKEN")
```

Or, you can pass an API key in directly:

```ruby
x = AI::Chat.new(api_key: "your-api-key-goes-here")
```

## Structured Output

Get back Structured Output by setting the `schema` attribute (I suggest using [OpenAI's handy tool for generating the JSON Schema](https://platform.openai.com/docs/guides/structured-outputs)):

```ruby
x = AI::Chat.new

x.system("You are an expert nutritionist. The user will describe a meal. Estimate the calories, carbs, fat, and protein.")

x.schema = '{"name": "nutrition_values","strict": true,"schema": {"type": "object","properties": {  "fat": {    "type": "number",    "description": "The amount of fat in grams."  },  "protein": {    "type": "number",    "description": "The amount of protein in grams."  },  "carbs": {    "type": "number",    "description": "The amount of carbohydrates in grams."  },  "total_calories": {    "type": "number",    "description": "The total calories calculated based on fat, protein, and carbohydrates."  }},"required": [  "fat",  "protein",  "carbs",  "total_calories"],"additionalProperties": false}}'

x.user("1 slice of pizza")

x.assistant!
# => {"fat"=>15, "protein"=>5, "carbs"=>50, "total_calories"=>350}
```

## Include images

You can include images in your chat messages using the `user` method with the `image` or `images` parameter:

```ruby
# Send a single image
x.user("What's in this image?", image: "path/to/local/image.jpg")

# Send multiple images
x.user("What are these images showing?", images: ["path/to/image1.jpg", "https://example.com/image2.jpg"])
```

The gem supports three types of image inputs:

- URLs: Pass an image URL starting with `http://` or `https://`.
- File paths: Pass a string with a path to a local image file.
- File-like objects: Pass an object that responds to `read` (like `File.open("image.jpg")` or a Rails uploaded file).

You can send multiple images, and place them between bits of text, in a single user message:

```ruby
z = AI::Chat.new
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
z = AI::Chat.new
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

## Set assistant messages manually

You can manually add assistant messages without making API calls, which is useful when reconstructing a past conversation:

```ruby
# Create a new chat instance
chat = AI::Chat.new

# Set the system message to establish the context
chat.system("You are a helpful assistant who provides information about planets.")

# First exchange about Mars
chat.user("Tell me about Mars.")
chat.assistant("Mars is the fourth planet from the Sun and the second-smallest planet in our Solar System. It's often called the 'Red Planet' because of its reddish appearance due to iron oxide (rust) on its surface. Mars has two small moons, Phobos and Deimos.")

# Second exchange about Mars' atmosphere
chat.user("What's the atmosphere like?")
chat.assistant("Mars has a very thin atmosphere compared to Earth. It consists of about 96% carbon dioxide, 1.9% nitrogen, 1.8% argon, and traces of oxygen and water vapor. The atmospheric pressure on Mars is only about 1% of Earth's at sea level, which means liquid water can't exist on the surface for long periods.")

# Third exchange about Mars' potential for life
chat.user("Could it support human life?")
chat.assistant("Mars currently can't support human life without significant technological assistance. Challenges include the thin atmosphere that doesn't protect from radiation, extreme cold temperatures, lack of liquid water on the surface, and no breathable air. However, NASA and other space agencies are researching how humans might live on Mars using habitats, life support systems, and possibly terraforming in the future.")

# Now continue the conversation with an API-generated response
chat.user("Are there any current missions to go there?")
response = chat.assistant!
puts response
```

This approach lets you recreate a conversation's history (perhaps from your database), and then continue it.

## Getting and setting messages directly

- You can call `.messages` to get an array containing the conversation so far.
- You can set `.messages` to replace the conversation with a provided array or ActiveRecord::Relation:

```ruby
# Create a new chat instance
chat = AI::Chat.new

# Set messages from an array of hashes
chat.messages = [
  { role: "system", content: "You are a helpful assistant." },
  { role: "user", content: "Hello!" },
  { role: "assistant", content: "How can I help you today?" }
]

# Set messages from ActiveRecord models
chat.messages = Message.where(conversation_id: 123)

# With images
chat.messages = [
  { role: "system", content: "You are a helpful assistant." },
  { role: "user", content: "What's in this image?", image: "path/to/image.jpg" },
  { role: "assistant", content: "I see a cat in the image." }
]

# With multiple images
chat.messages = [
  { role: "user", content: "Compare these images", images: ["image1.jpg", "image2.jpg"] }
]
```

### Custom attribute mappings

If your database columns or object attributes have different names, you can configure custom mappings:

```ruby
# Configure custom attribute mappings
chat = AI::Chat.new
chat.configure_attributes(
  role: :message_type,       # Instead of "role"
  content: :message_body,    # Instead of "content" 
  images: :attachments,      # For retrieving associated images
  image_url: :url            # Column on the image model that contains the URL/path
)

# Now works with custom column names
chat.messages = CustomMessage.where(conversation_id: 123)
```

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

## Reasoning Effort

When using reasoning models like `o3` or `o4-mini`, you can specify a reasoning effort level to control how much reasoning the model does before producing its final response:

```ruby
x = AI::Chat.new
x.model = "o4-mini"
x.reasoning_effort = "medium" # Can be "low", "medium", or "high"

x.user("Write a bash script that transposes a matrix represented as '[1,2],[3,4],[5,6]'")
x.assistant!
```

The `reasoning_effort` parameter guides the model on how many reasoning tokens to generate before creating a response to the prompt. Options are:
- `"low"`: Favors speed and economical token usage
- `"medium"`: (Default) Balances speed and reasoning accuracy
- `"high"`: Favors more complete reasoning

Setting to `nil` disables the reasoning parameter.

## TODOs

- Add a way to access the whole API response body (rather than just the message content).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/firstdraft/ai-chat. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/firstdraft/ai-chat/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AI Chat project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/firstdraft/ai-chat/blob/main/CODE_OF_CONDUCT.md).
