# 159 — Queue screen, process actions and failed jobs

**Phase** 13 · Processing  |  **Depends on** [040](../03-design-system/040-app-empty-state.md), [042](../03-design-system/042-app-progress-steps.md), [142](142-job-model.md), [143](143-job-runner.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The queue screen from the specification — unprocessed, queued and failed counts, grouped by context, with a process
action per group — plus process all and process selected with per-record progress and cancel, and a failures list
giving each reason with one-tap retry.

## Files

- `frontend/lib/features/processing/presentation/queue_screen.dart` (new)
- `frontend/lib/features/processing/presentation/process_actions.dart` (new)
- `frontend/lib/features/processing/presentation/failed_jobs_screen.dart` (new)

## Steps

1. Show unprocessed, queued and failed counts from queries; group by context; offer a process action per group.
2. Process all and process selected report per-record progress through `AppProgressSteps` (task 042), allow cancel at
   any point, and end with a summary of succeeded and failed.
3. Failures show the reason recorded by the retry classifier, rendered through `AppErrorState` (task 040), and retry
   in one tap.

## Constraints

- Async state renders through `AsyncValueView` (task 040); every list carries all four states (FE-CONS-04).
- Counts come from queries and the list is virtualised; the queue is never materialised to draw the screen
  (FE-PERF-03).

## Definition of done

- [ ] A user can process one facility at a time.
- [ ] Interrupting a batch keeps everything already processed, and a failed job never damages the raw record.
- [ ] Tests: widget tests of grouping and counts, of progress, cancellation and the end-of-run summary in
      `process_actions.dart`, and of `failed_jobs_screen.dart` including its empty and failure states.
