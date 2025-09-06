import 'just-flake.just'

# Display the list of recipes
default:
    @just --list

# Run the development server
dev:
    nix run .#dev

# Run erb linter
lint-erb:
    bundle exec erb_lint --config .erb_lint.yml --lint-all -a

# Run rubocop linter
lint-rubocop:
    bin/rubocop -a

lint-brakeman:
    bin/brakeman --no-pager

# Run all lints
lint: lint-rubocop lint-erb lint-brakeman

# Run tests
test:
    rails db:test:prepare
    rails test:all

# Start Postgres SQL REPL
psql:
    rails dbconsole

# Start interactive Ruby session for debugging
console:
    rails console
