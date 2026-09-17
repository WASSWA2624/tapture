# 258 — Project and membership endpoints

**Phase** 24 · The minimal backend  |  **Depends on** [256](256-be-permissions.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Project registration and membership management over identifiers and settings only: the device announces a project it
already owns, and the server records who may see it and whether relay is enabled for it.

## Files

- `backend/src/routes/projects.ts` (new)
- `backend/src/services/projects.ts` (new)
- `backend/test/routes/projects.test.ts` (new)
- `backend/test/routes/members.test.ts` (new)

## Contract

```ts
POST /api/v1/projects    GET /api/v1/projects    PATCH /api/v1/projects/:id
GET /api/v1/projects/:id/members    POST /api/v1/projects/:id/members    DELETE /api/v1/projects/:id/members/:userId
```

## Steps

1. Accept the client-generated project identifier on registration; reject any request that would change it, and never
   generate a replacement.
2. `PATCH` covers name and relay settings — enabled, retention window within the permitted maximum, and the
   never-relay marking — and only a project manager or administrator may change them.
3. Membership changes are transactional and write an audit entry; a relay enablement change writes one too.

## Constraints

- Registration stores no record, photo, template or field value; the server holds metadata only (BE-DATA-03).
- A project the caller is not a member of returns 404 for every verb here (BE-API-09).

## Definition of done

- [ ] Registering or updating a project stores no record, photo or template content.
- [ ] An attempt to change a project identifier is refused, and the stored identifier is still the device's.
- [ ] Relay settings change only for a project manager or administrator, and the change is audited.
- [ ] Tests: route tests for registration, identifier-change refusal, membership add and remove across roles, and a
      test asserting no content column exists or is written.
