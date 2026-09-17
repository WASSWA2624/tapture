# 259 — Relay: accept, list and download packages

**Phase** 24 · The minimal backend  |  **Depends on** [258](258-be-projects-api.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three transit endpoints: an idempotent, size-limited upload that stores an opaque blob, a cursor-paginated list of
what the calling device has not yet acknowledged, and a download by identifier. Every one is scoped to an enrolled device
of a project member.

## Files

- `backend/src/routes/relay/push.ts` (new)
- `backend/src/routes/relay/fetch.ts` (new)
- `backend/src/services/relay/packages.ts` (new)
- `backend/src/repositories/relay.ts` (new)
- `backend/test/routes/relay_push.test.ts` (new)
- `backend/test/routes/relay_fetch.test.ts` (new)

## Contract

```ts
POST /api/v1/projects/:id/relay/packages                 // Idempotency-Key header
GET  /api/v1/projects/:id/relay/packages                 // limit, cursor -> unacknowledged for this device
GET  /api/v1/projects/:id/relay/packages/:packageId       // ciphertext bytes
```

## Steps

1. Store the blob without parsing it and record only the metadata BE-RELAY-06 permits; set `expires_at` from the
   project's retention window at insert time.
2. Refuse a project marked never-relay, or one with relay disabled, in the service — not merely in the client
   (BE-RELAY-09).
3. Replaying an idempotency key returns the original result and creates nothing; a package over the configured size
   limit gives 413.
4. List and download only for an enrolled, unrevoked device of a member of that project, and log every access with
   package identifier, project, device and outcome.

## Constraints

- Relay is the backend's one **optional** capability (§72): an organisation that never enables it must still have a
  complete, fully working product.
- The server has no code path that decrypts, unpacks, parses or inspects a package (BE-RELAY-02, BE-SEC-08).
- A non-member, or a device of a non-member, gets 404 for a package that exists (BE-API-09).

## Definition of done

- [ ] The server never attempts to decrypt, unpack or inspect a package, and stores no metadata beyond the permitted
      list.
- [ ] Replaying an upload with the same idempotency key creates nothing and returns the first result.
- [ ] A non-member device receives 404 for a package that exists, and every access is logged.
- [ ] Tests: route tests for upload success, oversize, relay-disabled project, never-relay project, replay, listing
      across a cursor boundary, download, and cross-project isolation.
