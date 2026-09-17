# 260 — Relay: acknowledge, delete and report state

**Phase** 24 · The minimal backend  |  **Depends on** [259](259-be-relay-push.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Acknowledgement, the delete decision that runs in the same transaction as it, and the version-vector endpoint that tells
a returning device what it still owes and what it has yet to receive.

## Files

- `backend/src/routes/relay/ack.ts` (new)
- `backend/src/routes/relay/state.ts` (new)
- `backend/src/services/relay/purge_decision.ts` (new)
- `backend/src/domain/version_vector.ts` (new)
- `backend/test/services/purge_decision.test.ts` (new)
- `backend/test/routes/relay_state.test.ts` (new)

## Contract

```ts
POST /api/v1/relay/ack                        // { packageIds[] }, Idempotency-Key header
GET  /api/v1/projects/:id/relay/state         // vectors per device, queue depth for this device
```

## Steps

1. Record the acknowledgement, recompute completeness against the currently enrolled, unrevoked devices of the project,
   and delete the package and its rows in the same transaction when the set is complete.
2. Replaying an acknowledgement changes nothing and still returns success, including when the package has already been
   purged.
3. Advance the caller's version-vector counter as part of the same transaction, and return the vectors and queue depth
   from `state`.
4. Compare vectors in `domain/version_vector.ts` as pure functions, so the ordering logic is unit-testable without a
   database.

## Constraints

- Relay is the backend's one **optional** capability (§72): an organisation that never enables it must still have a
  complete, fully working product.
- Purge on acknowledgement is immediate, and the acknowledgement is recorded in the same transaction as the delete
  decision (BE-RELAY-03, BE-DATA-09).
- Vectors carry counters and device identifiers only; the server never merges, resolves or orders changes
  (BE-RELAY-06, BE-RELAY-11).

## Definition of done

- [ ] A fully acknowledged package is gone immediately, not at the next job run.
- [ ] Replaying an acknowledgement is a no-op, including after the package has been purged.
- [ ] The vectors returned match exactly what was pushed and acknowledged.
- [ ] Tests: unit tests over vector comparison; integration tests for partial acknowledgement, completion with delete,
      idempotent replay, and a device revoked mid-flight no longer counting towards completeness.
