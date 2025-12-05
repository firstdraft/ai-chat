# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2025-12-05

### Breaking Changes

- **Renamed `items` to `get_items`**: The method now clearly indicates it makes an API call. Returns an `AI::Items` wrapper that delegates to the underlying response while providing nice display formatting.

### Added

- **Reasoning summaries**: When `reasoning_effort` is set, the API now returns chain-of-thought summaries in `get_items`. These show the model's reasoning process (e.g., "Planning Ruby version search", "Confirming image tool usage").

- **Improved console display**: `AI::Chat`, `AI::Message`, and `AI::Items` now display nicely in IRB and Rails console with colorized, formatted output via AmazingPrint.

- **HTML output for ERB templates**: All display objects have a `to_html` method for rendering in views. Includes dark terminal-style background for readability.

- **`AI::Message` class**: Messages are now `AI::Message` instances (a Hash subclass) with custom display methods.

- **`AI::Items` class**: Wraps the conversation items API response with nice display methods while delegating all other methods (like `.data`, `.has_more`, etc.) to the underlying response.

- **TTY-aware display**: Console output automatically detects TTY and disables colors when output is piped or redirected.

- **New example**: `examples/16_get_items.rb` demonstrates inspecting conversation items including reasoning, web searches, and image generation.

## [0.4.0] - 2025-11-25

### Breaking Changes

- **Removed `previous_response_id`**: Use `conversation_id` instead for managing conversation state. The gem now exclusively uses OpenAI's Conversations API for continuity. Simply store the `conversation_id` and set it on a new `AI::Chat` instance to continue a conversation.

- **Renamed `assistant!` to `generate!`**: The method that sends messages to the API and generates a response is now called `generate!` to better reflect its purpose.

### Changed

- **Default model**: Changed from `gpt-4.1-nano` to `gpt-5.1`.

- **Default reasoning effort**: Remains `nil`. For `gpt-5.1`, this is equivalent to `"none"` reasoning.

- **Web search tool**: Renamed from `web_search_preview` to `web_search` to match OpenAI's GA release.

### Added

- **`last_response_id` reader**: New public accessor to get the ID of the most recent response. Useful for background mode workflows where you need to track, retrieve, or cancel a specific response from another process.

- **Automatic conversation management**: The gem now automatically creates and manages conversations via OpenAI's Conversations API. The `conversation_id` is set after the first `generate!` call and maintained across subsequent calls.

- **`items` method**: Retrieve all conversation items (messages, tool calls, reasoning) from OpenAI's API with `chat.items`.

- **Improved test coverage**: Added integration tests for conversation continuity, file handling, and conversation items retrieval.

### Notes

- **Background mode limitation**: There is currently no serialization-friendly hook to resume a background response from a different process. You can use `last_response_id` to track the response, but resuming requires the original `AI::Chat` instance or manual API calls.

- **Manual message manipulation**: If you manually add assistant messages to the `messages` array without a `:response` object, the `prepare_messages_for_api` method may not slice the history as expected on the next `generate!` call. This is an edge case for users who directly manipulate the messages array.

## [0.0.0] - 2025-07-22

- Initial implementation.
