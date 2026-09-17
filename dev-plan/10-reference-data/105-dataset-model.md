# 105 — Reference dataset model and repository

**Phase** 10 · Reference data  |  **Depends on** [056](../04-data-layer/056-reference-tables.md), [062](../04-data-layer/062-repository-interfaces.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Immutable `ReferenceDataset` and `ReferenceRow` models with mappers over the reference tables, and
`ReferenceRepositoryImpl` behind the repository interface from 111. Every importer, browser and matcher in this phase
goes through these types.

## Files

- `frontend/lib/features/reference/domain/reference_dataset.dart` (new)
- `frontend/lib/features/reference/data/reference_repository_impl.dart` (new)

## Contract

```dart
class ReferenceDataset {
  final String id, name, keyColumn;
  final List<String> columns;      // in import order
  final DatasetSource source;      // csv | xlsx | json | device
  final DateTime importedAt;
  final int rowCount;
}

class ReferenceRow {
  final String id, datasetId, key;
  final Map<String, String> values;
  final bool addedOnDevice;
}
```

## Steps

1. Keep `columns` in import order, so a later export writes the columns back out in the order they arrived.
2. Rows added on the device are flagged, so export can include them and the browser can show them apart.

## Constraints

- Nothing under `features/reference/domain/` imports Flutter or Drift; the mapper lives in `data/` (FE-STR-05).
- Row lookups by key are indexed at the table, not filtered in Dart (FE-PERF-06).

## Definition of done

- [ ] Presentation never sees a Drift row: datasets and rows are reachable only through the repository interface.
- [ ] Tests: round-trip mapper test over a dataset and its rows; repository tests against an in-memory database, and the fake later tasks use.
- [ ] Contract above is implemented exactly, with nothing else made public.
