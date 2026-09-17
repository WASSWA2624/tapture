# 162 — Record model, repository and status lifecycle

**Phase** 14 · Records  |  **Depends on** [018](../01-orchestration/018-network-test.md), [054](../04-data-layer/054-records-table.md), [062](../04-data-layer/062-repository-interfaces.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A record read in one call with its values, photos, status flags and context snapshot, behind a repository interface,
together with the one canonical status set and the transitions the app will allow between its members.

## Files

- `frontend/lib/features/records/domain/record_entry.dart` (new)
- `frontend/lib/features/records/domain/record_lifecycle.dart` (new)
- `frontend/lib/features/records/data/record_repository_impl.dart` (new)

## Contract

```dart
enum RecordStatus {
  draft, captured, queued, processing, extracted,
  needsReview, approved, failed, archived, deleted,
}
```

## Steps

1. One read returns the record with its values, photos, status flags and context snapshot; callers never assemble it
   from three queries.
2. The statuses above are the whole set. Export is a timestamp and an export membership, never a status.
3. Reject an illegal transition with a validation failure rather than silently applying it.

## Constraints

- `domain/` is pure Dart; Drift rows are mapped at the `data/` boundary (FE-STR-05).

## Definition of done

- [ ] Manual records go DRAFT to NEEDS_REVIEW to APPROVED without touching processing states.
- [ ] An illegal transition fails validation instead of being applied.
- [ ] Tests: unit tests over the full transition table; repository tests against an in-memory database covering the
      round-trip mapper, plus the fake later tests use.
