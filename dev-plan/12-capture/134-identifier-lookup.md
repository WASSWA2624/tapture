# 134 — Identifier-first lookup

**Phase** 12 · Capture  |  **Depends on** [054](../04-data-layer/054-records-table.md), [111](../10-reference-data/111-lookup-exact-match.md), [133](133-barcode-scanner.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A scanned or typed identifier resolves to one of the specification's three outcomes: an existing record to open, a
reference-dataset match that prefills a new record, or a new record carrying just the identifier.

## Files

- `frontend/lib/features/capture/domain/identifier_lookup.dart` (new)

## Steps

1. Search the project's records first, then reference datasets (199), then offer a new record with the identifier
   already filled.
2. Where the identifier matches more than one record, list the matches rather than guessing.
3. Each outcome is one tap from the result.

## Constraints

- Lookup over 10,000 records stays under 300ms against a realistically seeded database, with the measurement in the pull request (FE-PERF-01, FE-PERF-06, FE-TEST-09).
- The identifier is bound as a parameter, never concatenated into a query (FE-SEC-05).

## Definition of done

- [ ] All three outcomes are reachable in one tap each.
- [ ] Tests: unit tests for a record match, a reference-dataset match, no match, and a duplicate identifier present on two records; a measurement test for the 300ms lookup budget.
