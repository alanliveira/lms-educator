# Multi-Tenancy Notes

## Tenant Model

Use `Company` as the tenant unless the user changes the product model. Decide explicitly whether:

- a user belongs to exactly one company; or
- a user can belong to many companies and selects an active tenant.

The current code is mostly single-company per user (`has_one :company_user`). Multi-company support would require changing associations to `has_many`.

## Tenant Resolution

Resolve tenant centrally, not separately in each controller. Candidate sources:

- authenticated user's selected company;
- subdomain;
- custom domain;
- path or explicit company identifier for public signup/login only.

Add a request-local tenant, for example `Current.company`, after authentication or during public company signup/login flows. Treat params as hints, not authorization.

## Scoping Rules

Use tenant-aware access for all tenant data:

```ruby
Current.company.users.find(params[:id])
Current.company.company_courses.find_by!(course_id: params[:course_id])
policy_scope(Course)
```

Avoid:

```ruby
User.find(params[:id])
Company.find(params[:id])
Course.find(params[:course_id])
CompanyCourse.find_by(company_id: params[:id], course_id: params[:course_id])
```

## Authorization Rules

Implement Pundit policies for tenant resources:

- `CompanyPolicy`
- `UserPolicy`
- `CoursePolicy`
- `CourseClassPolicy`
- `CompanyCoursePolicy`

Global admin may cross tenant boundaries only where explicitly allowed. Company users should be limited to their company. Students should be limited to courses/classes visible for their company.

## Test Scenarios

Create two companies with users and courses. Authenticate as a company user or student in company A, then attempt to:

- view user from company B;
- update user from company B;
- toggle status for user from company B;
- change a user's `company_id`;
- view course class from company B;
- toggle access for company B course relation;
- remove a course from company B.

Expected result: forbidden, not found, or redirect with no state change. Prefer one consistent behavior for tenant boundary violations.
