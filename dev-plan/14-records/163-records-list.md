# 163 — Records list, filters and sort

**Phase** 14 · Records  |  **Depends on** [037](../03-design-system/037-app-chip.md), [038](../03-design-system/038-app-card.md), [040](../03-design-system/040-app-empty-state.md), [162](162-record-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The paged records list showing number, name, identifier, context and status, narrowed by context, template, status,
date, operator, condition and the quality flags, and ordered by number, capture date or name in either direction.
The last filter and sort are remembered per project.

## Files

- `frontend/lib/features/records/presentation/records_list_screen.dart` (new)
- `frontend/lib/features/records/presentation/records_filter_sheet.dart` (new)
- `frontend/lib/features/records/presentation/records_sort_menu.dart` (new)

## Steps

1. Virtualise and page the list; show list and detail side by side on expanded layouts (FE-RESP-05).
2. Show active filters as removable chips (task 037), combined with AND and clearable in one tap.
3. Apply filters and ordering in the query; never sort or filter a materialised list in Dart.
4. Persist the last filter and sort per project.

## Constraints

- Rows are `AppListTile` and thumbnails are the shared thumbnail; the screen invents no row of its own
  (FE-CONS-06).
- Page size comes from `AppConstants`; the project's records are never materialised to draw a screen (FE-PERF-03).

## Definition of done

- [ ] Ten thousand records scroll smoothly.
- [ ] Filters combine and clear in one tap; sorting works ascending and descending on all three keys.
- [ ] Filter and sort survive a restart, per project.
- [ ] Tests: widget tests of paging and the empty state, of `records_filter_sheet.dart` including its empty and
      failure states, and of `records_sort_menu.dart`; a scroll measurement backing the 10,000-row claim
      (FE-TEST-09).
