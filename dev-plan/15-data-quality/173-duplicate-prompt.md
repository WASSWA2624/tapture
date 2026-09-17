# 173 — Duplicate prompt and resolution

**Phase** 15 · Data quality  |  **Depends on** [041](../03-design-system/041-app-dialog-service.md), [051](../04-data-layer/051-tombstones-table.md), [058](../04-data-layer/058-duplicates-table.md), [165](../14-records/165-record-detail.md), [172](172-identity-hash.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The warning raised at the moment of saving, and the four outcomes behind it: override the existing record, keep both
and link them, discard the new one, or merge field by field. The side-by-side comparison is the gate — no outcome is
reachable without a person having seen the difference.

## Files

- `frontend/lib/features/quality/presentation/duplicate_prompt.dart` (new)
- `frontend/lib/features/quality/presentation/duplicate_compare_screen.dart` (new)
- `frontend/lib/features/quality/presentation/duplicate_merge_sheet.dart` (new)
- `frontend/lib/features/quality/domain/duplicate_override.dart` (new)
- `frontend/lib/features/quality/domain/duplicate_link.dart` (new)

## Contract

```dart
enum DuplicateChoice { overrideExisting, keepBoth, discardNew, mergeFields }

Future<DuplicateChoice?> showDuplicatePrompt(
  BuildContext context,
  RecordEntry incoming,
  DuplicateCandidate match,
);
```

## Steps

1. The prompt offers the four choices and shows the differing values with them. Dismissing it leaves both records and
   the pair unresolved rather than choosing on the user's behalf.
2. The comparison screen puts the two records side by side with their photos, highlights only the fields that differ,
   and shows photo counts and capture details — time, person, context — for both.
3. Override writes the new values onto the existing record, keeps the replaced values in history, attaches the new
   photos, and writes an audit entry naming the override. It is reachable only from the comparison.
4. The merge sheet decides per field: keep mine, take theirs, or keep both as a note. Photos from the discarded side
   can be carried onto the surviving record.
5. Keep both writes the pair into the duplicates table (105) as related, so each record carries a badge linking to
   its counterpart and the pair appears in 326.

## Constraints

- Replaced values and discarded photos are written beside the originals, never over them (FE-SEC-08).
- Every resolution writes an audit row naming the choice, both record ids and the person (FE-SEC-09).
- The prompt asks one question through the shared dialog service, never its own dialog (FE-CONS-05, FE-SIMP-07).

## Definition of done

- [ ] The prompt never appears without the differing values, and any of the four choices can be made without opening
      either record separately.
- [ ] Overriding is impossible without passing through the comparison; afterwards history holds the replaced values
      and the audit trail names the override.
- [ ] Merging can keep photos from the discarded side on the survivor; keeping both leaves each record showing a badge
      and a link to its counterpart.
- [ ] Tests: widget tests of `duplicate_prompt.dart`, `duplicate_compare_screen.dart` and `duplicate_merge_sheet.dart`
      including empty and failure states; unit tests of `duplicate_override.dart` asserting history holds the replaced
      values and an audit row is written, and of `duplicate_link.dart` with no Flutter binding.

## Out of scope

- Clearing a backlog of pairs away from the save flow; that is task 174.
