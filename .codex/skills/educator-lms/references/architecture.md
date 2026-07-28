# Architecture Notes

## Rails Upgrade Strategy

The app currently targets Rails 7.1.3.4 with `config.load_defaults 7.1`. Avoid jumping straight to Rails 8 without tests. Prefer:

1. Add characterization tests around authentication and tenant isolation.
2. Upgrade to Rails 7.2 first.
3. Run `bin/rails app:update` selectively and review diffs.
4. Resolve deprecations and dependency issues.
5. Replace `authentication-zero` with Rails native authentication patterns.
6. Introduce tenant context and policies.
7. Upgrade Rails to 8.x and update `config.load_defaults`.

## Local Commands

Use these checks when relevant:

```bash
bin/rails test
bin/rails zeitwerk:check
bundle exec rubocop
bin/rails routes
```

`brakeman` and `bundler-audit` may not be in the bundle. If security review is requested, add or run them explicitly with user approval when dependency installation/network is needed.

## Architecture Direction

Keep controllers thin:

- HTTP and params in controllers.
- Authorization in Pundit policies and scopes.
- Tenant filtering in policy scopes, model scopes, or query objects.
- Multi-record workflows in services only when controller action complexity justifies it.

Avoid putting request-local logic in models. Existing code such as course visibility based on `Current.user` should move toward a policy/query.

## Database Direction

Add database constraints for rules that must always hold:

- unique company identifier;
- unique company-course pair;
- unique user-company membership if users become multi-company;
- one owner per company when that rule is required;
- non-null booleans where tri-state is not intended.

Prefer migrations that backfill and validate data before adding strict constraints in production.
