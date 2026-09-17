# 020 — Shared constants

**Phase** 02 · Foundation services  |  **Depends on** [004](../01-orchestration/004-folder-scaffold.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

`frontend/lib/core/constants/app_constants.dart` is the one place every duration, size, limit, threshold and storage
key name is defined, so no later task writes a bare literal.

## Files

- `frontend/lib/core/constants/app_constants.dart` (new)

## Contract

```dart
abstract final class AppConstants { static const listPageSize = 50; static const imageLongEdge = 1600; ... }
```

## Steps

1. Define animation durations, the debounce interval, list page size, image long edge and quality, retention days, confidence thresholds and secure-storage key names.
2. Group them into nested abstract final classes by area rather than one flat list.

## Constraints

- Numbers, durations and keys come from here or from the design tokens; a literal in feature code is a defect (FE-CODE-09).
- List page size is read from here by every paged query, so the value is stated once (FE-PERF-03).

## Definition of done

- [x] Every value later phases need — page size, image long edge and quality, retention days, confidence thresholds, secure-storage key names, animation durations, debounce interval — resolves here.
- [x] Grouping is by area, so a caller reaches a value through one nested class rather than a flat namespace.
- [x] Tests: `frontend/test/core/app_constants_test.dart` asserts each value sits in a sane range and that no two storage key names collide.
