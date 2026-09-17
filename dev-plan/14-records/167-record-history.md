# 167 — Record history view

**Phase** 14 · Records  |  **Depends on** [051](../04-data-layer/051-tombstones-table.md), [165](165-record-detail.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The chronological story of one record as the specification describes it: captures, processing runs, edits with
previous and new values, approvals, merges and exports, read entirely from the local audit table.

## Files

- `frontend/lib/features/records/presentation/record_history_screen.dart` (new)

## Definition of done

- [ ] A reviewer can reconstruct every change without a server.
- [ ] Tests: widget test of `record_history_screen.dart`, including its empty and failure states.
