# 261 — Relay purge job and storage ceilings

**Phase** 24 · The minimal backend  |  **Depends on** [260](260-be-relay-ack.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The scheduled job that deletes expired packages whether or not anyone acknowledged them, and the per-project and
per-organisation ceilings that turn unchecked growth into a clear error instead of a full disk.

## Files

- `backend/src/jobs/purge.ts` (new)
- `backend/src/services/relay/quota.ts` (new)
- `backend/src/domain/retention.ts` (new)
- `backend/test/jobs/purge.test.ts` (new)
- `backend/test/services/storage_quota.test.ts` (new)

## Contract

```ts
runPurge(now: Date): Promise<PurgeReport>   // { deleted, bytesReclaimed, oldestAgeSeconds, failures }
```

## Steps

1. Delete every package past its expiry in bounded batches, each batch a transaction, whether acknowledged or not.
2. Compute the retention window in `domain/retention.ts` and clamp it to the hard maximum of 90 days in code, not by
   policy; a configured value above it is a boot failure.
3. Record counts, ages and bytes reclaimed on every run, expose them as metrics, and make the last report readable by an
   administrator.
4. Check the project and organisation ceilings before accepting an upload, returning a typed error naming the ceiling
   reached and what to do about it.

## Constraints

- Relay is the backend's one **optional** capability (§72): an organisation that never enables it must still have a
  complete, fully working product.
- No archive, no cold copy, no analytics extract of a package on the way out (BE-RELAY-05); a device that misses the
  window re-synchronises from a peer.
- Purge is provable: the clock is injected so a test can advance it (BE-RELAY-08, BE-TEST-05).

## Definition of done

- [ ] Advancing the clock past the window removes packages that no device ever fetched, and reports how many and how
      old.
- [ ] A configured retention window above the hard maximum stops the process at boot.
- [ ] Exceeding a storage ceiling returns a clear, actionable error rather than filling the disk.
- [ ] Tests: tests driving the injected clock across the acknowledgement and expiry paths, and quota tests below, at and
      above each ceiling.
