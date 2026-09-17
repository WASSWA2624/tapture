# 257 — Organisation user endpoints

**Phase** 24 · The minimal backend  |  **Depends on** [256](256-be-permissions.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Listing, creating and updating organisation users, restricted to administrators — and the one directory endpoint that is
not: `GET /auth/me`, which returns the caller's own identity and role grants and is what the device caches to keep
working with the server unreachable (§70.4, §71.2).

## Files

- `backend/src/routes/org/users.ts` (new)
- `backend/src/routes/auth/me.ts` (new)
- `backend/src/services/users.ts` (new)
- `backend/test/routes/org_users.test.ts` (new)
- `backend/test/routes/auth_me.test.ts` (new)

## Contract

```ts
GET /api/v1/org/users    POST /api/v1/org/users    PATCH /api/v1/org/users/:id
GET /api/v1/auth/me
```

## Steps

1. `PATCH` covers role change and status change only; a password never travels through this surface.
2. `GET /auth/me` returns the account identity, organisation, role, project grants and the grant validity window the
   device needs in order to cache them.
3. A role change writes an audit entry naming actor, target, old role and new role.

## Constraints

- Listing is cursor-paginated with `limit`, `cursor` and `nextCursor`; no endpoint here returns an unbounded list
  (BE-API-06).
- Authorisation is decided in the service through `can`, never in the route (BE-SEC-06).

## Definition of done

- [ ] `GET /auth/me` returns the identity and grants the device caches, and never a credential or a provider key.
- [ ] A non-administrator cannot list or modify organisation users, and learns nothing from the attempt.
- [ ] Tests: route tests for each endpoint across every role, including the unauthorised paths and cursor pagination
      over a page boundary.
