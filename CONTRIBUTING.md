# Contributing

Thanks for contributing to `ai-chat`! This gem is intentionally beginner-friendly, so please keep public-facing docs and examples simple and progressively introduced.

## Development setup

- Ruby: `~> 3.2` (see `ai-chat.gemspec`)
- Install dependencies: `bundle install`

## Running the test suite

- Run unit specs: `bundle exec rspec`
- Integration specs make real API calls and require `OPENAI_API_KEY` (they are skipped automatically if it’s not set).
- Disable coverage locally (optional): `NO_COVERAGE=1 bundle exec rspec`

## Code style / quality

- Format/lint: `bundle exec standardrb --fix`
- Smell checks (optional): `bundle exec reek`

## Running examples (real API calls)

The `examples/` directory is both documentation and a practical validation suite.

1. Set `OPENAI_API_KEY` (or create a `.env` file in the repo root):
   ```bash
   OPENAI_API_KEY=your_openai_api_key_here
   ```
2. Run a quick overview: `bundle exec ruby examples/01_quick.rb`
3. Run everything: `bundle exec ruby examples/all.rb`

## Documentation expectations

- If you change the public API, update `README.md`.
- If you change behavior in a user-visible way, update `CHANGELOG.md`.
- Keep examples easy to paste into IRB; use short variable names (`a`, `b`, `c`, …) to match existing style in `examples/`.

