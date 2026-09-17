# 136 — The two save paths

**Phase** 12 · Capture  |  **Depends on** [057](../04-data-layer/057-jobs-table.md), [120](120-capture-session-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Both primary actions on the capture screen. Capture and analyse persists everything and then queues a processing job;
save raw persists everything, sets status `CAPTURED` and runs nothing at all.

## Files

- `frontend/lib/features/capture/domain/save_and_analyse.dart` (new)
- `frontend/lib/features/capture/domain/save_raw.dart` (new)

## Steps

1. Persist record, photos, captions and field values first; enqueue afterwards (103).
2. A failed enqueue leaves a complete `CAPTURED` record and a retryable job — never a lost record and never a partial one.
3. The raw path makes no network call and no AI call of any kind, whatever the settings say.

## Constraints

- The raw path is provably silent: the integration test asserts zero outbound calls (FE-SEC-03, FE-SEC-04).
- Neither path may report success before the record and its evidence are durable (FE-STATE-07).
- Saved, saving and failed are announced to screen readers as they happen (FE-A11Y-07).

## Definition of done

- [ ] Losing connectivity between save and enqueue never loses the record.
- [ ] Forty records can be captured offline in sequence with no processing triggered.
- [ ] Tests: unit test that a failed enqueue leaves a complete `CAPTURED` record with a retryable job; integration test of the raw path asserting zero outbound calls across forty records.

## Out of scope

- Running the job. This task only writes and enqueues; the worker, its retries and its progress belong to phase 13 · Processing.
