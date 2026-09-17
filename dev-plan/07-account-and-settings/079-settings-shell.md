# 079 — Settings shell and its section screens

**Phase** 07 · Account and settings  |  **Depends on** [038](../03-design-system/038-app-card.md), [068](../05-file-storage/068-thumbnail-cache.md), [069](../05-file-storage/069-storage-guard.md), [073](../06-app-shell/073-nav-shell.md), [078](078-settings-store.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The settings root listing the specification's eight sections, each its own route, plus the three section screens this
phase owns: capture defaults, storage usage and About. Adding a setting later is one more tile.

## Files

- `frontend/lib/features/settings/presentation/settings_screen.dart` (new)
- `frontend/lib/features/settings/presentation/capture_settings_screen.dart` (new)
- `frontend/lib/features/settings/presentation/storage_settings_screen.dart` (new)
- `frontend/lib/features/settings/presentation/about_screen.dart` (new)
- `frontend/lib/app/router.dart` (edit)

## Steps

1. Root sections in this order, grouped by `AppSectionHeader`, one `AppListTile` each: Operator, Capture, AI, Language,
   Storage, Data, Security, About. Declare each section's route in `router.dart`; sections whose screens arrive in a
   later phase keep their tile and gain a route there, so the list is never restructured.
2. Capture settings: camera default, auto-filled dates, GPS, photo quality, folder strategy and naming pattern, each
   read and written through `settings_store.dart`. Every row carries a one-line plain-language statement of its effect,
   and the folder-strategy row states on screen that it applies to new files only.
3. Storage settings: space used per project broken down into photos, documents, audio and exports; free headroom from
   `storage_guard.dart`; "Clear cache" calling `cache_cleanup.dart`; the retention window control.
4. About: application version, build number, licences through the platform licence page, and links to the plan and the
   specification.

## Constraints

- Rows are `AppListTile` under `AppSectionHeader`; no screen here invents a row, a switch or a section style (FE-CONS-06).
- GPS is off by default and the row says why it is off (FE-SEC-07).
- Clearing the cache removes derived copies only; no original file is touched (FE-SEC-08).
- A new setting has to justify why no default is right for most people (FE-SIMP-12).

## Definition of done

- [ ] Adding a setting later means adding one tile, not restructuring a screen.
- [ ] Changing the folder strategy affects only new files, and the screen states that.
- [ ] A user can see space used per project and free it without a file manager.
- [ ] Tests: widget tests for all four screens covering loading, empty and failure through `AsyncValueView`, plus a
  storage test asserting a cache clear deletes no original file and updates the displayed totals.

## Out of scope

- The AI, Language and Data section screens; their tiles route to nothing until those phases land.
- Project-scoped switches, which phase 08 owns.
