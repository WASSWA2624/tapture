# 083 — Project list and the current project

**Phase** 08 · Projects  |  **Depends on** [038](../03-design-system/038-app-card.md), [040](../03-design-system/040-app-empty-state.md), [078](../07-account-and-settings/078-settings-store.md), [082](082-project-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The landing screen: every project as one row with its record count, unprocessed count and last-worked time, most
recently worked first. Opening a row records the choice in `CurrentProject`, which persists it, restores it on the next
launch and is the single source every project-scoped route reads.

## Files

- `frontend/lib/features/projects/presentation/project_list_screen.dart` (new)
- `frontend/lib/features/projects/presentation/current_project.dart` (new)

## Contract

```dart
final class CurrentProject extends Notifier<String?> {
  void open(String projectId);
  void close();
}

final currentProjectProvider = NotifierProvider<CurrentProject, String?>(CurrentProject.new);
final currentProjectDetailsProvider = Provider<Project?>(...);
```

## Steps

1. Feed the list from one `watch` query that returns the counts and the last-worked time with the rows, using the
   status and `updatedAt` indexes from 092. No query per row.
2. Render rows with `AppListTile` and all four states through `AsyncValueView`. The empty state offers "Create a
   project" and "Import a bundle".
3. Persist the open project id as a declared key in `settings_store.dart` and restore it on launch; if the stored id no
   longer resolves, clear it and stay on this screen rather than failing.
4. Opening a row sets `CurrentProject` and then honours the intended destination the router guard carried, so a
   diverted deep link resumes.

## Constraints

- One source of truth for the open project: no screen, controller or service keeps its own copy of the id
  (FE-STATE-06).
- Counts come from the watch query and the database indexes, not from a loop or a timer (FE-PERF-03, FE-PERF-06).
- The two-second claim is asserted by a measurement, not assumed (FE-TEST-09).

## Definition of done

- [ ] Opening the app lands here with counts rendered in under two seconds on the reference device.
- [ ] Reopening the app returns to the last opened project without asking; a deleted last project clears cleanly.
- [ ] Loading, empty, populated and failure all render through `AsyncValueView`.
- [ ] Tests: widget tests of all four states; a unit test of `CurrentProject` restoring a persisted id, clearing an
  unresolvable one, and resuming a carried destination; a measured test of the landing budget.

## Out of scope

- The archived filter; the archive task adds it.
