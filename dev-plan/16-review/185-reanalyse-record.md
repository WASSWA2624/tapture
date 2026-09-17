# 185 — Re-analyse a record

**Phase** 16 · Review  |  **Depends on** [142](../13-processing/142-job-model.md), [151](../13-processing/151-proposal-application.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Run processing again over a record whose human work must survive. The results arrive as a diff of proposed changes,
accepted or declined field by field.

## Files

- `frontend/lib/features/review/presentation/reanalyse_action.dart` (new)

## Steps

1. Queue the job through 262 and show its progress on the record rather than blocking the screen.
2. Present each new value beside the current one, marking which current values are verified or manually typed.
3. Write only the changes the user accepts; declining leaves the record exactly as it was.

## Definition of done

- [ ] A verified or manually typed field is offered as a proposal, never applied silently.
- [ ] Accepting some proposals and declining others leaves exactly the accepted ones written.
- [ ] Tests: widget test of `reanalyse_action.dart` covering the diff, partial acceptance, a full decline, and its
      empty and failure states, including one asserting a verified field is offered rather than applied.
