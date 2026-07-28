---
name: educator-lms
description: Project-specific guidance for the Educator LMS Rails application in /home/allanzitto/educator_lms. Use when working on this app's Rails 7.1 to Rails 8 upgrade, replacing authentication-zero with Rails native authentication, implementing company-based multi-tenancy, fixing tenant isolation/security, adding tests, or reviewing architecture, controllers, models, policies, routes, and migrations for this LMS.
---

# Educator LMS

Use this skill for the local Rails app at `/home/allanzitto/educator_lms`.

## Project Snapshot

- Rails app: Rails 7.1.3.4, Ruby 3.3.0, Node.js 22.1.0, PostgreSQL, Propshaft, Turbo, Stimulus, css/js bundling.
- Version manager: use `mise` with `.tool-versions` as the operational source for local Ruby and Node versions.
- Authentication: currently generated from `authentication-zero`; target is Rails 8 native authentication.
- Authorization: Pundit is present, but policies are currently incomplete.
- Roles: Rolify with roles such as `admin`, `company`, and `student`.
- Tenant candidate: `Company`.
- Current relationship model: `User has_one :company_user`, `User has_one :company`, `Company has_many :users`.
- Course visibility: companies are connected to courses through `CompanyCourse`, with `can_be_viewed`.
- Test suite: Rails test runner exists, but the project may have little or no test coverage.

## Working Rules

Read relevant files before changing behavior. Prefer focused changes and Rails conventions already present in the app. Do not rely on hidden UI links for security; enforce access in controllers, policies, scopes, and database constraints.

When changing authorization or tenancy, add request/model tests that demonstrate tenant isolation. Tests that fail against current code are acceptable when creating a characterization suite for planned refactors; label them clearly in the final response.

Do not inspect or expose `.env` values. It exists locally and should remain ignored.

## Main Workflows

### Review or Plan Rails 8 Upgrade

Read [references/architecture.md](references/architecture.md) and [references/dependencies.md](references/dependencies.md). Check `.tool-versions`, `.ruby-version`, `.node-version`, `Gemfile`, `Gemfile.lock`, `config/application.rb`, `config/environments/*.rb`, `Dockerfile`, and test status.

Prefer this sequence:
1. Add safety tests for auth and tenant isolation.
2. Upgrade Rails 7.1 to 7.2 and resolve deprecations.
3. Remove `authentication-zero` by adapting to Rails native authentication patterns.
4. Introduce tenant resolution and tenant-scoped policies.
5. Upgrade to Rails 8 and update `config.load_defaults`.

### Replace Authentication

Read [references/authentication.md](references/authentication.md). Do not run the Rails authentication generator directly over existing files without first comparing generated output in a temporary location or branch. The app already has `User`, `Session`, `Current`, password reset, email verification, and custom company login flow.

### Implement Multi-Tenancy

Read [references/tenancy.md](references/tenancy.md). Treat `Company` as the tenant unless the user chooses another model. Add `Current.company` or equivalent tenant context, resolve it centrally, and scope all data access through tenant-aware queries or Pundit scopes.

### Add Tests

Start with request tests for:
- login/logout and session persistence;
- users from another company cannot be viewed, edited, activated, moved, or deleted;
- courses and course classes from another company cannot be accessed;
- company users can only manage their own company;
- admin can cross tenant boundaries only when explicitly intended.

Use helper methods for creating companies, users, roles, sessions, and courses. Keep fixtures/factories minimal and readable.

### Manage Runtime Versions

Read [references/dependencies.md](references/dependencies.md). Prefer `mise install`, `mise current`, and `mise exec -- <command>` when validating Ruby, Bundler, Node, Yarn, Rails, and asset commands. Keep version files synchronized when changing Ruby or Node.

## Known Risk Areas

Check these files early:
- `app/controllers/application_controller.rb`
- `app/controllers/sessions_controller.rb`
- `app/controllers/registrations_controller.rb`
- `app/controllers/users_controller.rb`
- `app/controllers/companies_controller.rb`
- `app/controllers/courses_controller.rb`
- `app/controllers/course_classes_controller.rb`
- `app/models/current.rb`
- `app/models/user.rb`
- `app/models/company.rb`
- `app/models/company_user.rb`
- `app/models/course.rb`
- `app/policies`
- `db/schema.rb`
- `config/routes.rb`
- `.tool-versions`
- `.ruby-version`
- `.node-version`
- `Dockerfile`

Common issues in this app:
- direct `Model.find(params[:id])` without tenant scoping;
- mutating state via `GET`;
- strong params allowing `active` or `company_id` from unsafe contexts;
- model code depending on `Current.user`;
- missing Pundit policies/scopes;
- missing unique indexes for tenant join tables;
- `authentication-zero` code mixed with custom company login behavior.
