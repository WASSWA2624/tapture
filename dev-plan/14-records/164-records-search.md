# 164 — Search records

**Phase** 14 · Records  |  **Depends on** [035](../03-design-system/035-app-text-field.md), [163](163-records-list.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One indexed search across field values, captions, transcripts and OCR text, feeding the records list from the search
field and answering in under 300 milliseconds over ten thousand records.

## Files

- `frontend/lib/features/records/data/record_search.dart` (new)

## Steps

1. Maintain an indexed search table, kept in step by repository writes or database triggers in the same transaction
   as the write.
2. Index on write, never on read; a query never scans field values directly.

## Constraints

- The 300ms budget is FE-PERF-01 and is asserted against a realistically seeded database, not assumed (FE-PERF-06,
  FE-TEST-09).

## Definition of done

- [ ] A search over ten thousand records returns in under 300 milliseconds.
- [ ] Editing, adding or deleting a record updates its search entry in the same transaction.
- [ ] Tests: performance test with a seeded database asserting the budget; repository tests over index maintenance on
      insert, edit and delete.
