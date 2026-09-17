# 111 — Lookup matching, picking, prefill and unlink

**Phase** 10 · Reference data  |  **Depends on** [041](../03-design-system/041-app-dialog-service.md), [054](../04-data-layer/054-records-table.md), [110](110-lookup-binding-config.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The whole lookup path behind a bound field: exact match on the key then on the normalised name, a scored fuzzy
fallback, a picker when several rows match, the prefill that fills the mapped fields with provenance, and the
per-field unlink when the operator edits one of them.

## Files

- `frontend/lib/features/reference/domain/lookup_matcher.dart` (new)
- `frontend/lib/features/reference/domain/fuzzy_matcher.dart` (new)
- `frontend/lib/features/reference/presentation/lookup_picker_sheet.dart` (new)
- `frontend/lib/features/reference/domain/lookup_prefill.dart` (new)
- `frontend/lib/features/reference/domain/lookup_unlink.dart` (new)

## Steps

1. Fast path first: match on the key column, then on the normalised name — case, whitespace and punctuation
   insensitive — before any fuzzy work is attempted.
2. Fuzzy fallback uses a normalised edit distance plus token overlap, returns its confidence score to the caller, and
   is used only when the binding enables it and the score clears its threshold.
3. A near miss is offered as a suggestion the operator accepts; it never fills silently.
4. Several matches open the picker sheet, showing the columns that distinguish the rows rather than just the name.
5. Prefill writes each mapped field with source LOOKUP and the dataset row id in provenance, and never overwrites a
   value already marked verified.
6. Editing one prefilled field detaches that field alone; the remaining fields keep their link and their provenance.

## Constraints

- All four domain files are pure Dart with no Flutter binding; only the picker sheet is a widget (FE-STR-05).
- Matching over a large dataset runs off the UI thread and against an indexed key column
  (FE-PERF-02, FE-PERF-06).
- The picker is the shared bottom sheet API, and no-match behaviour follows the binding rather than the screen
  (FE-CONS-05).

## Definition of done

- [ ] A near miss offers a suggestion rather than filling silently, and several matches always ask.
- [ ] Prefilled fields show the link affordance, remain editable, and a verified value is left alone.
- [ ] Editing the phone number does not detach the supplier name.
- [ ] Tests: unit tests for key, case and whitespace variants; unit tests of the fuzzy scorer over a table of real-world name variants with expected scores; unit tests that prefill skips a verified field and that `lookup_unlink.dart` detaches one field only, both with no Flutter binding; widget test of `lookup_picker_sheet.dart` covering empty and failure states.
