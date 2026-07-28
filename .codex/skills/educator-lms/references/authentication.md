# Authentication Notes

## Current State

The app uses `authentication-zero` and customizes:

- `User` with `has_secure_password`, `verified`, `active`, roles, email verification, password reset;
- `Session` with user agent and IP;
- `Current` with `session`, `user_agent`, `ip_address`;
- company-aware sign-in and sign-up paths using `params[:company][:identifier]`.

The target is Rails native authentication from Rails 8 while preserving business behavior.

## Migration Guidance

Do not blindly run `bin/rails generate authentication` over the app. Generate into a temporary Rails app or temporary branch and compare patterns.

Move toward:

- an `Authentication` controller concern;
- `allow_unauthenticated_access` style API, or a clearly named local equivalent;
- `start_new_session_for(user)`;
- `terminate_session`;
- `resume_session`;
- central handling of `Current.session`;
- request-local metadata assignment before session creation.

## Session Security

Avoid storing raw session IDs as the only cookie credential if replacing auth. Prefer a session token generated for the `Session` record and stored in a signed, HTTP-only cookie.

On password change, destroy other sessions using clear comparison against the current session record.

## Business Rules To Preserve

- inactive users cannot log in;
- email verification exists and should be intentionally retained or explicitly removed;
- company sign-up approval flow exists;
- login/signup may need tenant context;
- history records are created for login/logout when that behavior remains desired.

## Test Coverage

Cover:

- valid login creates a session and cookie;
- inactive user cannot log in;
- logout destroys only the current session;
- password reset token works and invalid token fails;
- email verification flips `verified`;
- tenant identifier in login/signup cannot be used to attach to an arbitrary company unless intended.
