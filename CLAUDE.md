# Claude Instructions

This file contains instructions for Claude.

## Git Commits

- When writing git commit messages:
    - Don't add "co-authored by Claude", or mention Claude at all.
    - Use good style (no more than 50 chars in subject line, 70 chars in lines of body, etc).
- Make sure you add a newline at the end of files you create, and any other files you touch.

## Code Style

- This project uses StandardRB for linting. Always run `bundle exec standardrb --fix` before committing Ruby code.
- Follow Ruby community conventions and idioms.
- Always end sentences in comments and documentation with a period.

## Project-Specific Guidelines

- This is an OpenAI API client gem that wraps the official openai/openai-ruby library.
- The openai-ruby library is cloned in the `openai-ruby/` directory for reference.
- When making changes, ensure compatibility with the underlying OpenAI client.
- Prefer clear, simple implementations over clever code.

## Testing

- Run tests with `bundle exec rspec`.
- Ensure all tests pass before committing.
- Add tests for new functionality.

## Dependencies

- For any task, first look to see if good libraries/gems/packages exist and discuss the pros and cons of using them vs writing our own implementation.
- This project already depends on the official OpenAI Ruby client - leverage it where possible.

## Documentation

- Always use proper punctuation in comments, commit messages, and documentation.
- End all sentences with appropriate punctuation (usually a period).
- Keep documentation clear and concise.