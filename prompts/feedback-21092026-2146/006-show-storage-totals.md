# 006 — Show storage totals

**Feedback:** FBK0000026 · **Type:** Gap · **Priority:** P4 · **Effort:** M · **Depends on:** none

## Goal
Storage shows total, used and available bytes for the volume that holds the storage root, on phone and desktop. A failed read shows the screen's error state, not "Plenty of space". Choosing a folder is prompt 007.

## Evidence
- FBK0000026: the operator wants available, total and used space, and a way to set the storage path. `prompts/TAPTURE-21092026-2146/screenshots/FBK0000026.png` shows Storage with a qualitative free-space line ("Plenty of space"), cache, per-project sizes and retention. Android, compact, portrait, dark. The path is prompt 007.
- Root cause: `StorageGuard` only classifies free bytes (`frontend/lib/core/files/storage_guard.dart:210`, `:220`). `_posixFreeBytes` keeps the available column and drops total and used. The screen prints `_headroomLabel` (`frontend/lib/features/settings/presentation/storage_settings_screen.dart:60`) and maps a failed check to `HeadroomState.ample` (`:285`).

## Scope
- Reach: Android (reported), Windows and POSIX desktops, both orientations, all themes, 200 percent text. Web is excluded: the storage screen is already `dart:io` and device volume stats are not available in the browser sandbox (open task 286). Do not fake totals there.
- Change: `StorageGuard` (add a volume read; keep `check()`), Android `com.tapture.app/files` in `MainActivity.kt` using `StatFs` (no new package), `StorageSettingsScreen`, `Copy`.
- Do not change: cache clear, retention, per-project breakdown, capture blocking, or where files are stored.

## Rules
- FE-STR-11: only `StorageGuard` and the existing files channel touch the volume.
- FE-CONS-09, FE-L10N-01, FE-L10N-04: three figures through `Copy.fileSize` and `Copy` sentences, not concatenated fragments.
- FE-STATE-11, FE-A11Y-05: failure is visible; ample, low and critical stay as words beside the numbers.
- FE-TEST-01, FE-TEST-02, FE-TEST-03: extend `StorageGuard.fake` / the `freeBytes` seam so tests never run `df` or PowerShell.
- FE-FLOW-06: no new dependency.

## Steps
1. Record the work under `05-file-storage`, or `cd frontend && dart run tool/new_task.dart 05-file-storage storage-volume-totals "Show storage volume totals"` (FE-FLOW-08).
2. Add a volume result with total, used and free bytes. POSIX `df -Pk` already has 1024-blocks, used and available. Windows `Get-PSDrive` has `Used` and `Free`; total is their sum. Android: a `volumeStats` method on `com.tapture.app/files` using `StatFs` for the root path. Keep `check()` and headroom thresholds.
3. A failed volume read is a `FailureResult`. `storage_settings_screen.dart` must not substitute `HeadroomState.ample`.
4. Under `Copy.settingsHeadroomHeader`, show total, used and available with `Copy.fileSize`, and keep the ample / low / critical label.
5. Unit-test the parser and the fake with known byte counts. Widget-test the three figures and the failure state in `frontend/test/features/settings/presentation/storage_settings_screen_test.dart`.

## Acceptance criteria
- [ ] Given a volume of known size, Storage shows that total, used and available in compact portrait and expanded landscape, light, dark and outdoor, at text scale 2.
- [ ] Low and critical volumes still show their existing words as well as the numbers.
- [ ] A failed probe shows the error state with retry, not "Plenty of space".
- [ ] Cache, projects and retention rows are unchanged.
- [ ] The path request in FBK0000026 stays in prompt 007.

## Verification
- `cd frontend && dart run tool/verify.dart --fast`, then `dart run tool/verify.dart`.
- No goldens unless a storage golden already covers this screen; if so, update only that file and list it.
