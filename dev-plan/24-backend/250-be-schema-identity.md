# 250 — Schema: organisations, users, devices, projects and members

**Phase** 24 · The minimal backend  |  **Depends on** [249](249-be-db-connection.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The first two migrations: the identity tables the server exists to hold, and the project registration and membership
tables that carry identifiers and settings but no project content.

## Files

- `backend/migrations/001_identity.sql` (new)
- `backend/migrations/002_projects.sql` (new)
- `backend/test/repositories/identity.test.ts` (new)
- `backend/test/repositories/membership.test.ts` (new)

## Steps

1. `organisations`; `users` with email, password hash, role, organisation and status; `devices` with the device
   identifier, user, enrolled time, last seen and revoked state.
2. Unique email per organisation, unique device identifier, both by constraint.
3. `projects` stores the identifier the device generated, name, organisation and relay settings — and no column that
   could hold a record, a photo, a template or any other content.
4. `project_members` joins a user to a project with a role and an optional context scope, unique per pair.

## Constraints

- Client identifiers are authoritative: the server never reassigns a project identifier and never invents one
  (BE-DATA-02).
- Foreign keys, uniqueness and not-null are declared in the database, not only checked in code (BE-DATA-07); every
  index carries a comment naming the query it serves (BE-DATA-08); all timestamps are `timestamptz` (BE-DATA-10).

## Definition of done

- [ ] A project row carries the client-generated identifier and there exists no column able to hold project content.
- [ ] Email is unique per organisation and the device identifier is globally unique, enforced by constraint.
- [ ] Tests: repository integration tests for user and device creation and lookup, and for membership with and without
      a context scope, including the cross-organisation isolation case.
