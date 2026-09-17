# 143 — Job runner, retry and backoff

**Phase** 13 · Processing  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [142](142-job-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A claimed job runs its stages in order in the isolate runner, persisting each completed stage so a resume skips it,
stopping cleanly on cancel, and classifying every failure so transient ones retry with bounded backoff and permanent
ones stop at once.

## Files

- `frontend/lib/features/processing/domain/job_runner.dart` (new)
- `frontend/lib/features/processing/domain/job_retry.dart` (new)

## Steps

1. Persist stage completion before moving on, so a resumed job does not redo finished work.
2. Honour a cancel token between stages: the record stays intact and the job stays resumable.
3. Classify failures as transient — network, timeout, rate limit, provider 5xx — or permanent — authentication,
   unparseable response after repair, unsupported media, missing template.
4. Retry transient failures with exponential backoff up to a capped attempt count; fail permanent ones on the first
   attempt.
5. Write the failure reason onto the job so the queue screen can show it verbatim.

## Constraints

- Stage work goes through the isolate runner with progress and cancellation; none of it touches the UI thread
  (FE-PERF-02).
- Backoff is bounded: a provider outage must not produce a tight retry loop (FE-PERF-08).

## Definition of done

- [ ] Cancelling mid-run leaves the record intact and the job resumable from the next stage.
- [ ] A resumed job skips stages already marked complete.
- [ ] A provider outage backs off instead of burning battery; a permanent failure stops without a second attempt.
- [ ] Tests: unit tests over resume, cancellation and both failure classes, with no Flutter binding.
