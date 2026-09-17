# 113 — Context model, repository and persistence

**Phase** 11 · Context  |  **Depends on** [052](../04-data-layer/052-projects-table.md), [062](../04-data-layer/062-repository-interfaces.md), [083](../08-projects/083-project-list.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The context feature's data layer: immutable models for the hierarchy definition, the current values and named
presets; the repository that reads and writes all three against the context tables; and restoration of the active
context when a project is opened, so it survives screen changes, backgrounding and app restarts.

## Files

- `frontend/lib/features/context/domain/context_state.dart` (new)
- `frontend/lib/features/context/data/context_repository_impl.dart` (new)
- `frontend/lib/features/context/data/context_persistence.dart` (new)

## Contract

```dart
class ContextLevel {
  const ContextLevel({required this.fieldKey, required this.order, this.datasetId});
  final String fieldKey;
  final int order;
  final String? datasetId;
}

class ContextState {
  const ContextState({this.levels = const [], this.values = const {}, this.pinned = const {}});
  final List<ContextLevel> levels;
  final Map<String, String> values; // fieldKey -> value, levels only
  final Map<String, String> pinned; // fieldKey -> value, non-hierarchical pins
  bool get isEmpty => levels.isEmpty && pinned.isEmpty;
}

class ContextPreset {
  const ContextPreset({required this.id, required this.name, required this.values, required this.pinned});
}
```

## Steps

1. Write the mappers both ways between each model and its context table rows.
2. Load the stored context for a project as part of opening it, before the first screen that reads it builds.
3. Persist on every change, not on a lifecycle callback.

## Constraints

- Models live in `domain/` as pure Dart; the implementation and every Drift import stay in `data/` (FE-STR-05, FE-STATE-05).
- Models are immutable with `copyWith`; no mutable collection escapes (FE-CODE-04).

## Definition of done

- [ ] A project with no defined levels loads an empty `ContextState` and writes no rows.
- [ ] Reopening the app resumes the same district, facility and department for the open project.
- [ ] Tests: unit round-trip mapper tests for `ContextState`, `ContextLevel` and `ContextPreset`; repository test against an in-memory database asserting the context reloads after a simulated restart.
