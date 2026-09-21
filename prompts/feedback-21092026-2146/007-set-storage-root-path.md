# 007 — Set storage root path

**Feedback:** FBK0000026 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **Depends on:** 006

## Goal
Storage shows the current storage-root path and lets the operator choose a folder that later resolves use. Existing files stay where they are.

## Evidence
- FBK0000026: set or manage the default storage path, on the same Storage screen as the space figures. Android, compact, portrait, dark.
- Root cause: `StorageRoot` always uses shared Documents on Android 11+ or the app documents directory (`frontend/lib/core/files/storage_root.dart:35`). `SettingKeys` has no path key (`frontend/lib/features/settings/domain/setting_keys.dart`).

## Scope
- Reach: Android, Windows, macOS, Linux and iOS, all themes and widths. Web is excluded: the browser cannot hold an app-chosen documents folder for the evidence tree.
- Change: a `SettingKey` for the root path, `StorageRoot.resolve` to prefer a persisted path that still passes the write probe, a row on `StorageSettingsScreen`.
- Do not change: volume figures (prompt 006), cache, retention, or file moves. Do not copy or delete the existing tree.

## Rules
- FE-SIMP-12: the control exists because the stored location is a fact the app cannot infer once someone has chosen one. Default remains today's `StorageRoot` when the key is empty.
- FE-STR-11, FE-SEC-01: the path is a preference, not a secret; platform folders stay inside `StorageRoot`.
- FE-SEC-08, FE-STATE-07: do not rewrite or delete evidence. Persist the key before confirming.
- FE-L10N-01, FE-L10N-11: the label is `Copy`; the path is user data, shown as stored.
- FE-A11Y-02: the row has a name and shows the current path.
- FE-TEST-01, FE-TEST-03.

## Steps
1. Record the work under `05-file-storage`, or `cd frontend && dart run tool/new_task.dart 05-file-storage choose-storage-root "Choose the storage root"` (FE-FLOW-08).

## Human review
⛔ Stop before step 2 and ask:
- FBK0000026 asks to manage the default storage path from Storage.
  - A) That path is the `StorageRoot` (the Tapture folder). Show it and save a new folder for later resolves. Leave existing files in place.
  - B) That path is only where exports are written. The evidence root stays fixed.
- Recommendation: A. If the answer is "proceed", do A. Do not relocate files in this prompt.

2. Add a nullable string `SettingKey` and include it in `SettingKeys.names`.
3. `StorageRoot.resolve`: if the key is a non-empty directory and the existing write probe succeeds, use it; otherwise use the current Documents fallback and surface the probe failure as today.
4. Storage gains a row: current path, and an action that picks a directory through the platform wrapper already used for folders. Confirm only after `SettingsStore.write` succeeds.
5. Tests with `StorageRoot.fake` and `SettingsStore.fake`: empty key uses the default; a saved path is the one `resolve` returns; a failed probe does not confirm.

## Acceptance criteria
- [ ] Storage shows the active root path on Android and desktop, compact and expanded, light and dark.
- [ ] Choosing a writable folder, restarting, and resolving the root returns that folder.
- [ ] An empty key still resolves to Documents / app documents, as today.
- [ ] No existing file is moved or deleted.
- [ ] Web does not show the picker.
- [ ] FBK0000026's path sentence is resolved. The figures stay in prompt 006.

## Verification
- `cd frontend && dart run tool/verify.dart --fast`, then `dart run tool/verify.dart`.
- No goldens unless an existing storage golden shows this row. List any file regenerated.
