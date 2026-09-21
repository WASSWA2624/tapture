# 109 — Records: find, read and change what was captured

**Phase** 14 · Records  |  **Depends on** [033](../03-design-system/033-app-page.md), [041](../03-design-system/041-app-dialog-service.md), [043](../03-design-system/043-app-photo-thumb.md), [051](../04-data-layer/051-tombstones-table.md), [054](../04-data-layer/054-records-table.md), [062](../04-data-layer/062-repository-interfaces.md), [068](../05-file-storage/068-thumbnail-cache.md), [097](../09-templates/097-field-editor-inline.md), [099](../09-templates/099-template-versioning.md), [107](../12-capture/107-capture.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Everything a person does with a record once capture is over. A record read in one call with its values, photos, status
flags and context snapshot, behind a repository interface, over the one canonical status set and the transitions the
app allows between its members; a paged, virtualised list showing number, name, identifier, context and status,
narrowed by context, template, status, date, operator, condition and the quality flags and ordered by number, capture
date or name in either direction, with the last filter and sort remembered per project; one indexed search across
field values, captions, transcripts and OCR text, feeding that list from the search field and answering in under 300
milliseconds over ten thousand records; a read-only detail view of fields, photos, context, provenance summary, status
and timestamps, with the entry point to each edit path; editing that changes values through the inline field editor,
adds or removes photos long after capture and swaps the template with a re-map by field key, each with its audit entry
and its status consequence; the chronological story of one record — captures, processing runs, edits with previous and
new values, approvals, merges and exports — read entirely from the local audit table; deletion as a tombstone with
undo from the snackbar, a recycle bin listing what is deleted with the days it has left and restoring it whole, and a
purge job that removes rows and files for good once the retention window has passed; and bulk approve, archive,
delete, export and re-process over a selection, with the count named throughout and the outcome reported per item.

## Files

Domain and data:

- `frontend/lib/features/records/domain/record_entry.dart` (new)
- `frontend/lib/features/records/domain/record_lifecycle.dart` (new)
- `frontend/lib/features/records/domain/purge_job.dart` (new)
- `frontend/lib/features/records/data/record_repository_impl.dart` (new)
- `frontend/lib/features/records/data/record_search.dart` (new)

List, filters and sort:

- `frontend/lib/features/records/presentation/records_list_screen.dart` (new)
- `frontend/lib/features/records/presentation/records_filter_sheet.dart` (new)
- `frontend/lib/features/records/presentation/records_sort_menu.dart` (new)

Read, edit and history:

- `frontend/lib/features/records/presentation/record_detail_screen.dart` (new)
- `frontend/lib/features/records/presentation/record_edit_screen.dart` (new)
- `frontend/lib/features/records/presentation/record_photos_editor.dart` (new)
- `frontend/lib/features/records/presentation/record_template_change.dart` (new)
- `frontend/lib/features/records/presentation/record_history_screen.dart` (new)

Removal and bulk actions:

- `frontend/lib/features/records/presentation/record_delete_action.dart` (new)
- `frontend/lib/features/records/presentation/recycle_bin_screen.dart` (new)
- `frontend/lib/features/records/presentation/record_bulk_actions.dart` (new)

## Contract

```dart
enum RecordStatus {
  draft, captured, queued, processing, extracted,
  needsReview, approved, failed, archived, deleted,
}
```

## Steps

1. Deliver the record, its repository and the status lifecycle first. One read returns the record with its values,
   photos, status flags and context snapshot; callers never assemble it from three queries. The statuses above are the
   whole set — export is a timestamp and an export membership, never a status. Reject an illegal transition with a
   validation failure rather than silently applying it.
2. Build the records list with its filter sheet and sort menu. Virtualise and page the list; show list and detail side
   by side on expanded layouts (FE-RESP-05). Show active filters as removable chips (task 037), combined with AND and
   clearable in one tap. Apply filters and ordering in the query; never sort or filter a materialised list in Dart.
   Persist the last filter and sort per project.
3. Add the search index behind the list. Maintain an indexed search table, kept in step by repository writes or
   database triggers in the same transaction as the write. Index on write, never on read; a query never scans field
   values directly.
4. Build the record detail screen. Show every value with its source and confidence band inline, with no extra tap to
   reveal them. Render photos as `AppPhotoThumb` (task 043); the full image opens only in the viewer (FE-PERF-04).
5. Open the three edit paths, so nothing about a saved record is frozen. Editing an approved record returns it to
   NEEDS_REVIEW and writes an audit entry holding the previous and new value. Adding a photo offers re-analysis;
   removing one flags every value whose evidence has gone instead of deleting the value. Changing template shows what
   maps by field key, what does not and what will be retired, before applying; unmapped values are kept as retired.
6. Build the history screen over the local audit table, so captures, processing runs, edits with previous and new
   values, approvals, merges and exports read as one chronology without a server.
7. Deliver delete, the recycle bin and the retention purge. Confirm through the dialog service (task 041), write the
   tombstone (task 051), hide the record from lists and offer undo in the snackbar. The bin shows remaining days per
   item and restores in one action; empty-now sits behind a strong confirmation. The purge runs on launch, takes only
   rows past the window, removes their files and cached thumbnails through the file storage services rather than
   touching the tree itself, logs the counts, and never purges a tombstone a merge still needs.
8. Finish with bulk actions over a selection from the list. Show the selected count in the action bar and name it
   again in every destructive confirmation. Apply per record, so one failure does not roll back the rest, and report
   succeeded and failed at the end.

## Constraints

- `domain/` is pure Dart; Drift rows are mapped at the `data/` boundary (FE-STR-05).
- Rows are `AppListTile`, thumbnails are the shared thumbnail, the search field is `AppTextField` and an empty list is
  `AppEmptyState`; no screen here invents a row of its own (FE-CONS-06).
- Page size comes from `AppConstants`; the project's records are never materialised to draw a screen (FE-PERF-03).
- The 300ms search budget is FE-PERF-01 and is asserted against a realistically seeded database, not assumed
  (FE-PERF-06, FE-TEST-09).
- Values are edited through the inline field editor of task 097, so validation and formatting stay identical to
  capture (FE-CONS-01).
- Deletion is a tombstone; files disappear only in the purge, after the window (FE-SEC-08).

## Definition of done

- [ ] Manual records go DRAFT to NEEDS_REVIEW to APPROVED without touching processing states.
- [ ] An illegal transition fails validation instead of being applied.
- [ ] Tests: unit tests over the full transition table; repository tests against an in-memory database covering the
      round-trip mapper, plus the fake later tests use.
- [ ] Ten thousand records scroll smoothly.
- [ ] Filters combine and clear in one tap; sorting works ascending and descending on all three keys.
- [ ] Filter and sort survive a restart, per project.
- [ ] Tests: widget tests of paging and the empty state, of `records_filter_sheet.dart` including its empty and
      failure states, and of `records_sort_menu.dart`.
- [ ] Tests: a scroll measurement backing the 10,000-row claim (FE-TEST-09).
- [ ] A search over ten thousand records returns in under 300 milliseconds.
- [ ] Editing, adding or deleting a record updates its search entry in the same transaction.
- [ ] Tests: performance test with a seeded database asserting the search budget.
- [ ] Tests: repository tests over index maintenance on insert, edit and delete.
- [ ] Every value shows its source without extra taps.
- [ ] Tests: widget test of `record_detail_screen.dart`, including its empty and failure states.
- [ ] Nothing about a record is permanently frozen.
- [ ] Values are never silently deleted when their evidence is removed, and unmapped values are retained as retired.
- [ ] Tests: test of the status transition and audit entry on edit.
- [ ] Tests: test of the evidence-removed flag.
- [ ] Tests: widget test of `record_template_change.dart`, including its empty and failure states.
- [ ] A reviewer can reconstruct every change without a server.
- [ ] Tests: widget test of `record_history_screen.dart`, including its empty and failure states.
- [ ] Files are retained until purge, so restore is always complete.
- [ ] A tombstone a merge still needs is never purged, and nothing leaves storage without an explicit action or an
      expired window.
- [ ] Tests: test of delete, undo and restore.
- [ ] Tests: test that a recent deletion survives a purge run and an unmerged tombstone is skipped.
- [ ] Tests: widget test of `recycle_bin_screen.dart`, including its empty and failure states.
- [ ] A bulk action reports how many succeeded and how many failed.
- [ ] A partial failure leaves the successful records changed and the failed ones untouched.
- [ ] Tests: widget test of `record_bulk_actions.dart`, including its empty and failure states, plus a test of the
      partial-failure summary.
