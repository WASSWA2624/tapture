# 178 — Variance screen

**Phase** 15 · Data quality  |  **Depends on** [038](../03-design-system/038-app-card.md), [177](177-variance-computation.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The deliverable view of a verification exercise: the differences for one record, and the differences across the whole
project, filtered by status and grouped by context.

## Files

- `frontend/lib/features/quality/presentation/variance_screen.dart` (new)

## Steps

1. Filter by `match`, `changed` and `missing`; group by context level; open a row into its record.
2. Show the missing and not-found sets of 331 as a filter here, not as a separate screen.

## Definition of done

- [ ] A project's changed, matching and missing items are readable without opening a record.
- [ ] Tests: widget test of `variance_screen.dart` covering each filter, the grouped list, a record-scoped view, and
      its empty and failure states.
