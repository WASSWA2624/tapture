# 126 — Photo tray with order, type and multi-select

**Phase** 12 · Capture  |  **Depends on** [036](../03-design-system/036-app-choice-field.md), [043](../03-design-system/043-app-photo-thumb.md), [120](120-capture-session-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The horizontal thumbnail strip with count and add action, drag reordering that sets the order everything else uses,
the sheet that assigns a photo type, and long-press multi-select with a contextual action bar.

## Files

- `frontend/lib/features/capture/presentation/photo_tray.dart` (new)
- `frontend/lib/features/capture/presentation/photo_reorder.dart` (new)
- `frontend/lib/features/capture/presentation/photo_type_sheet.dart` (new)
- `frontend/lib/features/capture/presentation/photo_multi_select.dart` (new)

## Steps

1. Show a type badge, caption indicator and processing state on each thumbnail, and keep the add action reachable at
   any scroll position.
2. Drag to reorder and persist the new order immediately; export and reports read the same order.
3. Offer the specification's photo types — front, serial, rating plate, damage and the rest — defaulting to the last
   used type for rapid tagging.
4. Long-press enters multi-select with a live count, select-all and clear; selection survives scrolling and rotation.

## Constraints

- Thumbnails only, cached by hash and size, with a cap on concurrent decodes (FE-PERF-04).
- The tray is virtualised and paged from `AppConstants`; a whole record's photos are never materialised (FE-PERF-03).
- Badges and selection carry an icon or text as well as colour (FE-A11Y-05).

## Definition of done

- [ ] Thirty photos scroll smoothly and the add button stays reachable throughout.
- [ ] The persisted order is the order export and reports use.
- [ ] A photo type feeds file naming and evidence tracking as soon as it is set.
- [ ] Tests: widget tests of `photo_tray.dart` (badges, ordering, empty state), `photo_reorder.dart` (order persisted across a rebuild), `photo_type_sheet.dart` (last-used default, every type reachable) and `photo_multi_select.dart` (count, select-all, clear, selection across scroll and rotation).
