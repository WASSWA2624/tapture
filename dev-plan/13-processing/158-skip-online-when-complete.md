# 158 — Skip the online stage, and cap what it costs

**Phase** 13 · Processing  |  **Depends on** [078](../07-account-and-settings/078-settings-store.md), [111](../10-reference-data/111-lookup-exact-match.md), [142](142-job-model.md), [143](143-job-runner.md), [146](146-identifier-extraction.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The online stage is skipped outright when local extraction plus a reference match already fills every required field
confidently, and whatever is left is bounded by an optional per-project daily cap with visible running counters.

## Files

- `frontend/lib/features/processing/domain/online_skip_rule.dart` (new)
- `frontend/lib/features/processing/domain/cost_guard.dart` (new)

## Steps

1. Skip when every required field is filled and confidently banded; write the skip reason onto the job.
2. Count requests and images as they are made and expose today's totals for the queue screen.
3. Block further online work at the cap with a message naming the cap and when it resets; the job stays queued rather
   than failing.

## Constraints

- The cap and thresholds come from the settings store per project, never from a literal (FE-CODE-09).

## Definition of done

- [ ] A scanned known asset completes with no online call.
- [ ] A user can always see how many calls have been made today.
- [ ] Reaching the cap stops online work with a clear message and leaves the queue intact.
- [ ] Tests: unit tests proving zero calls on the fully matched path, and counter and cap behaviour below, at and
      above the limit, with no Flutter binding.
