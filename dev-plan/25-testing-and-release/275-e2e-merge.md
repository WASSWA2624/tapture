# 275 — End-to-end: bundle merge and every export format

**Phase** 25 · Testing and release  |  **Depends on** [205](../18-export/205-zip-package.md), [218](../19-bundles-and-merge/218-merge-apply.md), [272](272-e2e-capture-to-export.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two integration runs over the file boundary — everything the app writes out and reads back. One covers a bundle
crossing between two databases; the other covers each export format an operator can hand over.

## Files

- `frontend/integration_test/merge_test.dart` (new)
- `frontend/integration_test/export_formats_test.dart` (new)

## Steps

1. `merge_test.dart` — export a bundle from one database and import it into a second; resolve one conflicting record;
   undo; redo. Assert idempotency by importing the same bundle twice and finding no second change, and a complete undo
   by comparing the second database against its pre-merge snapshot row for row.
2. `export_formats_test.dart` — with the network off, produce XLSX, CSV, JSON, PDF and ZIP from one project. Assert each
   opens in a reader, each carries the same record count as the database, and the ZIP's manifest checksums verify by the
   same routine the merge path uses before extraction.

## Constraints

- The bundle is checksum-verified and traversal-checked before extraction; a tampered archive is refused, not partly
  applied (FE-SEC-06).
- The merged audit trail travels with the data: after import, every value change still names its origin device
  (FE-SEC-09).

## Definition of done

- [ ] Re-importing a bundle changes nothing, and undo returns the target database to its exact pre-merge state.
- [ ] All five formats are produced with zero outbound calls and each matches the record count it claims.
- [ ] A corrupt or traversal-bearing bundle is rejected with a plain-language reason and no partial write.
- [ ] Tests: `merge_test.dart` and `export_formats_test.dart` run green offline against fakes, end to end.
