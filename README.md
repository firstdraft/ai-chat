# AI::Chat

This gem provides a class called `AI::Chat` that is intended to make it as easy as possible to use various AI chat completions APIs including OpenAI, Google's Gemini, and Anthropic's Claude.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "ai-chat"
```

And then, at a command prompt:

```
bundle install
```

Or, install it directly with:

```
gem install ai-chat
```

## Configuration

### Provider Selection

By default, the gem uses OpenAI, but you can specify other providers:

```ruby
# OpenAI (default)
openai_chat = AI::Chat.new(provider: :openai)

# Google's Gemini
gemini_chat = AI::Chat.new(provider: :gemini)

# Anthropic's Claude
claude_chat = AI::Chat.new(provider: :anthropic)
```

### API Tokens

Each provider looks for specific environment variables:

- OpenAI: `AI_TOKEN` or `OPENAI_TOKEN`
- Gemini: `GEMINI_TOKEN` or `GOOGLE_API_KEY`
- Anthropic: `ANTHROPIC_API_KEY`

You can also provide your token directly when instantiating a chat:

```ruby
x = AI::Chat.new(api_token: "your-token-goes-here", provider: :gemini)
```

### Models

Each provider has a default model, but you can specify a different one:

```ruby
# OpenAI default: "gpt-4o"
x = AI::Chat.new
x.model = "gpt-3.5-turbo"

# Gemini default: "gemini-1.5-pro"
y = AI::Chat.new(provider: :gemini)
y.model = "gemini-1.5-flash"

# Anthropic default: "claude-3-opus-20240229"
z = AI::Chat.new(provider: :anthropic)
z.model = "claude-3-sonnet-20240229"
```

## Simplest usage

```ruby
x = AI::Chat.new
x.system("You are a helpful assistant that speaks like Shakespeare.")
x.user("Hi there!")
x.assistant!
# => "Greetings, good sir or madam! How dost thou fare on this fine day? Pray, tell me how I may be of service to thee."

x.user("What's the best pizza in Chicago?")
x.assistant!
# => "Ah, the fair and bustling city of Chicago, renowned for its deep-dish delight that hath captured hearts and stomachs aplenty. Amongst the many offerings of this great city, 'tis often said that Lou Malnati's and Giordano's art the titans of the deep-dish realm. Lou Malnati's crust is praised for its buttery crispness, whilst Giordano's doth boast a stuffed creation that is nigh unto legendary. Yet, I encourage thee to embark upon thine own quest and savor the offerings of these famed establishments, for in the tasting lies the truth of which thy palate prefers. Enjoy the gastronomic adventure, my friend."
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

You can manually add assistant messages:

```rb
x.assistant("Greetings, good sir or madam! How dost thou fare on this fine day? Pray, tell me how I may be of service to thee.")
```

Useful if you are reconstructing a chat that has already happened.

## Getting and setting messages directly

- You can call `.messages` to get an array containing the conversation so far.
- TODO: Setting `.messages` will replace the conversation with the provided array.

## Provider-Specific Notes

### OpenAI

- Supports all features including structured output and images.
- Default model is `gpt-4o`.

### Gemini

- Handles system messages by converting them to user messages (as Gemini doesn't have a native system role).
- Uses a different format for structured output using `responseSchema`.
- Default model is `gemini-1.5-pro`.

### Anthropic

- Supports system messages and images.
- Handles schema generation differently by including it in the system context.
- Default model is `claude-3-opus-20240229`.

## TODOs

- Add a `reasoning_effort` parameter.
- Add the ability to set all messages at once, ideally with an ActiveRecord Relation.
- Add a way to access the whole API response body (rather than just the message content).
- Add provider-specific parameters (temperature, top_p, etc.).
- Support for streaming responses.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/firstdraft/ai-chat. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/firstdraft/ai-chat/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AI Chat project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/firstdraft/ai-chat/blob/main/CODE_OF_CONDUCT.md).