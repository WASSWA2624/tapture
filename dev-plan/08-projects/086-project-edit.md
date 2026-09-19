# 086 — Project details and per-project settings

**Phase** 08 · Projects  |  **Depends on** [078](../07-account-and-settings/078-settings-store.md), [084](084-project-create.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two screens over the same row: details — name, description, organisation, dates, status — and the project-scoped
switches that override the app defaults: AI enabled, do-not-send-images, GPS, folder strategy, confidence thresholds
and refined columns. A rename changes the display name only.

## Files

- `frontend/lib/features/projects/presentation/project_edit_screen.dart` (new)
- `frontend/lib/features/projects/presentation/project_settings_screen.dart` (new)

## Steps

1. Renaming writes `name`; `folderName` is immutable, so every existing file path keeps resolving and no file moves.
2. Persist project switches in the project's validated settings JSON on its own row, never in the app settings store.
   An unset value resolves to the app default from `settings_store.dart`; clearing an override returns it to that
   default.
3. State on each override row what the app-level default currently is, so the user can see what they are changing.
4. Status here writes the same field the archive action writes, so the two can never disagree.
5. Build both screens with `AppForm`, taking the unsaved-changes guard and error summary from the design system.

## Constraints

- The project row is the source of truth for project settings; the app store is only the default supplier
  (FE-STATE-06).
- Turning AI off and do-not-send-images on must genuinely stop every provider call for that project (FE-SEC-03).

## Definition of done

- [x] Existing file paths keep working after a rename, and no file is moved or copied.
- [x] A project can be made fully manual and offline with two switches.
- [x] An override wins over the app default, and clearing it falls back to that default.
- [x] Tests: widget tests of both screens across populated, dirty and failure states; a unit test asserting a rename
  leaves `folderName` unchanged; a unit test of override-then-fallback resolution.
