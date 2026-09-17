# 057 — Processing jobs, results and field evidence tables

**Phase** 04 · Local database  |  **Depends on** [054](054-records-table.md), [055](055-photos-table.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The provenance side of processing: the deferred job queue, the raw provider responses kept for audit, and the evidence
rows that tie every extracted value back to the photo region, document page or transcript segment it came from.

## Files

- `frontend/lib/core/db/tables/processing.dart` (new)
- `frontend/lib/core/db/tables/field_evidence.dart` (new)

## Steps

1. Jobs: `recordId`, `stage`, `status`, `attempts`, `lastError`, `queuedAt`, `startedAt`, `finishedAt`, `provider`,
   `model`.
2. Index jobs on `status` plus `queuedAt` so the queue screen reads without a scan.
3. Results: `jobId`, `requestSummary`, `rawResponse`, `parsedOk`, `tokensOrCost`.
4. Field evidence: `recordFieldId`, `sourceType` as photo, document or transcript, `photoId`, `documentId`, `page`,
   `region` as JSON bounding box, `snippet`, `confidence`; index on `recordFieldId`.

## Constraints

- All three tables declare the shared merge columns through `MergeColumns` in the migration that creates them
  (FE-SEC-09).
- `rawResponse` and `requestSummary` are written once when the job finishes and never rewritten; they are the audit of
  what the provider actually said (FE-SEC-08).
- `requestSummary` records shape and size, never a provider key or a bearer token (FE-SEC-01).

## Definition of done

- [x] Claiming the next queued job is served by the status index and cannot hand the same job to two workers.
- [x] A retried job increments `attempts` and keeps every earlier result row.
- [x] Any final value can be traced to its evidence row and from there to a photo region, document page or transcript
      segment.
- [x] Tests: `frontend/test/core/db/tables/processing_test.dart` covers queue ordering, retry accounting and result
      immutability; `field_evidence_test.dart` asserts the three source types resolve and that deleting a record field
      leaves a tombstone rather than an orphan. Both against an in-memory database, covering their migration steps.
