# 169 — Bulk actions on records

**Phase** 14 · Records  |  **Depends on** [126](../12-capture/126-photo-tray.md), [163](163-records-list.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Several records selected from the list and approved, archived, deleted, exported or re-processed in one go, with the
count named throughout and the outcome reported per item.

## Files

- `frontend/lib/features/records/presentation/record_bulk_actions.dart` (new)

## Steps

1. Show the selected count in the action bar and name it again in every destructive confirmation.
2. Apply per record, so one failure does not roll back the rest, and report succeeded and failed at the end.

## Definition of done

- [ ] A bulk action reports how many succeeded and how many failed.
- [ ] A partial failure leaves the successful records changed and the failed ones untouched.
- [ ] Tests: widget test of `record_bulk_actions.dart`, including its empty and failure states, plus a test of the
      partial-failure summary.
