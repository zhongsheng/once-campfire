# AGENTS

## Project overview
Campfire is a Ruby on Rails chat application. The primary code lives in:
- `app/` for controllers, models, views, jobs, channels, and assets
- `config/` for routes and environment configuration
- `db/` for schema and migrations
- `test/` for automated tests

## Development workflow
- Setup: `bin/setup`
- Run the server: `bin/rails server`

## Testing & linting
- Run the test suite: `bin/rails test`
- Lint Ruby: `bundle exec rubocop`

## General conventions
- Follow standard Rails conventions for file placement and naming.
- Prefer minimal, focused changes with clear tests when possible.
