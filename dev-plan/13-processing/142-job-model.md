# 142 — Processing job model, repository and queue

**Phase** 13 · Processing  |  **Depends on** [050](../04-data-layer/050-column-mixins.md), [057](../04-data-layer/057-jobs-table.md), [062](../04-data-layer/062-repository-interfaces.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One job per record — stage, attempt count, outcome and failure reason — persisted through a repository, with the
queue operations that let exactly one runner own a job at a time and hand it back after a crash.

## Files

- `frontend/lib/features/processing/domain/processing_job.dart` (new)
- `frontend/lib/features/processing/domain/job_queue.dart` (new)
- `frontend/lib/features/processing/data/processing_repository_impl.dart` (new)

## Contract

```dart
enum JobStage { prepare, onDevice, detect, online, normalise, validate }

abstract interface class JobQueue {
  Future<String> enqueue(String recordId);
  Future<ProcessingJob?> claim(Duration lease);
  Future<void> complete(String jobId);
  Future<void> fail(String jobId, String reason, {required bool permanent});
}
```

## Steps

1. Stages run in the contract's order; the job records the last one completed.
2. Claim inside one transaction (task 050) and stamp a lease, so two runners cannot take the same job.
3. Release an expired lease on the next claim, so a job killed mid-run becomes claimable again.
4. Read the concurrency cap from the settings store rather than a literal.

## Constraints

- Enqueue, claim, complete and fail are each one transaction; a half-written claim is a defect (FE-STATE-07).
- Drift types stop at `data/`; the job model and queue interface are pure Dart (FE-STR-05).

## Definition of done

- [ ] Killing the app mid-job leaves the job claimable again once the lease expires, not lost.
- [ ] Two concurrent claims never return the same job.
- [ ] Tests: unit tests over stage ordering and lease expiry; repository tests for `processing_repository_impl.dart`
      against an in-memory database, covering the round-trip mapper, plus the fake later tests use.
