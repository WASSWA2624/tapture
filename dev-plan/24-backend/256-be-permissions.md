# 256 — Role matrix and permission checks

**Phase** 24 · The minimal backend  |  **Depends on** [255](255-be-auth-tokens.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One permission function covering every capability, expressed as pure domain logic over administrator, project manager,
reviewer and field operator, plus the table-driven test that asserts every role against every capability.

## Files

- `backend/src/domain/permissions.ts` (new)
- `backend/test/domain/permission_matrix.test.ts` (new)

## Contract

```ts
can(principal: Principal, capability: Capability, scope?: Scope): boolean
```

## Steps

1. Implement the four roles of the specification, including a membership's optional context scope narrowing a
   project-level grant.
2. Call `can` from services; a route never decides a permission for itself, so a new route cannot forget the check.
3. Where a capability is refused because the caller cannot see the resource at all, the service raises the not-found
   error, not the forbidden one.

## Constraints

- `domain/` stays pure: no HTTP, no database client, no framework import (BE-STR-05).
- Membership is not an oracle — invisible and forbidden look identical to the caller (BE-API-09).
- Extending the capability list extends the matrix test in the same change (BE-TEST-04).

## Definition of done

- [ ] A user who cannot see a project receives 404, not 403.
- [ ] Every capability is decided in one place, and no route contains a role comparison.
- [ ] Tests: the full role-by-capability matrix as a table test, including the context-scoped cases.
