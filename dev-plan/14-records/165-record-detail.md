# 165 — Record detail screen

**Phase** 14 · Records  |  **Depends on** [033](../03-design-system/033-app-page.md), [043](../03-design-system/043-app-photo-thumb.md), [162](162-record-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A read-only view of one record — fields, photos, context, provenance summary, status and timestamps — with the entry
points to each edit path.

## Files

- `frontend/lib/features/records/presentation/record_detail_screen.dart` (new)

## Steps

1. Show every value with its source and confidence band inline, with no extra tap to reveal them.
2. Render photos as `AppPhotoThumb` (task 043); the full image opens only in the viewer (FE-PERF-04).

## Definition of done

- [ ] Every value shows its source without extra taps.
- [ ] Tests: widget test of `record_detail_screen.dart`, including its empty and failure states.
