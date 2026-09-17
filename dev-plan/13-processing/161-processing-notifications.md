# 161 — Processing notifications

**Phase** 13 · Processing  |  **Depends on** [005](../01-orchestration/005-dependency-allowlist.md), [142](142-job-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One local notification when a batch finishes or fails, carrying the succeeded and failed counts and opening the
review list when tapped.

## Files

- `frontend/lib/features/processing/data/notifications.dart` (new)

## Steps

1. Local notifications only — no push, no remote service; the plugin passes the dependency allowlist of task 005
   first.
2. Ask for the notification permission at first use and continue silently when it is refused.

## Constraints

- A notification carries counts and a route, never field values or project data (FE-SEC-07, FE-SEC-10).

## Definition of done

- [ ] A refused notification permission never stops or delays processing.
- [ ] Tests: tests for `notifications.dart` against a fake notification platform asserting one notification per
      batch, its counts and its tap route, plus the fake later tests use.
