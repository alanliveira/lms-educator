# Dependency and Version Management

## mise Is Preferred

Use `mise` to manage local runtime versions for this project. The operational version file is `.tool-versions`.

Current expected versions:

```text
ruby 3.3.0
nodejs 22.1.0
```

Use these commands before Rails, Bundler, Node, Yarn, or asset work:

```bash
mise install
mise current
mise exec -- ruby -v
mise exec -- node -v
mise exec -- bundle exec rails -v
```

When running app commands, prefer:

```bash
mise exec -- bundle install
mise exec -- bundle exec rails test
mise exec -- bundle exec rubocop
mise exec -- yarn install --frozen-lockfile
mise exec -- yarn build
mise exec -- yarn build:css
```

If `mise` is unavailable, report that clearly and fall back to the shell's active Ruby/Node only for inspection or low-risk checks.

## Files To Keep In Sync

When changing Ruby:

- `.tool-versions`
- `.ruby-version`
- `Gemfile` `ruby`
- `Dockerfile` `ARG RUBY_VERSION`
- `Gemfile.lock` Ruby platform/version section after bundle update

When changing Node:

- `.tool-versions`
- `.node-version`
- `Dockerfile` `ARG NODE_VERSION`
- `yarn.lock` only when dependency resolution changes

## Current File Notes

This project currently has:

- `.tool-versions`: `nodejs 22.1.0`, `ruby 3.3.0`
- `.ruby-version`: `ruby-3.3.0`
- `.node-version`: `22.1.0`
- `Gemfile`: `ruby '3.3.0'`
- `Dockerfile`: `ARG RUBY_VERSION=3.3.0`, `ARG NODE_VERSION=22.1.0`

Before editing versions, inspect all of these files. Prefer a single version change commit instead of mixing runtime upgrades with application refactors.

## Rails Upgrade Notes

For Rails 7.1 to 7.2 to 8.x work, verify runtimes first:

```bash
mise install
mise exec -- bundle install
mise exec -- bundle exec rails zeitwerk:check
mise exec -- bundle exec rails test
```

Only then change Rails constraints and regenerate lockfiles.
