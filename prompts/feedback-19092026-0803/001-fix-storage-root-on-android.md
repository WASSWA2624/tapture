# 001 — Fix the storage root on Android

**Feedback:** FBK0000002 · **Type:** Defect · **Priority:** P2 · **Effort:** S · **Depends on:** —

## Goal
On Android, `StorageRoot.resolve()` creates and returns the `Tapture/` folder without asking for any
permission. Storage settings then shows the real cache and per-project totals, and Clear cache works. The
screen looks right at compact, medium and expanded widths, in light, dark and outdoor.

## Evidence
- FBK0000002: the reporter says Storage does not work on Android. `screenshots/FBK0000002.png` shows the
  Storage screen replaced by the generic error state ("A service this screen uses failed", Try again).
  Android, mobile, compact, portrait, system dark, text scale 1, app 1.0.0.
- The error screen is gone, but the fault remains. Commit `9715bcd` made `_load` fall back to
  `_usageOnly` (`frontend/lib/features/settings/presentation/storage_settings_screen.dart:277-313`), so a
  failed root now shows placeholders instead. `screenshots/FBK0000006.png` (Android, a later build) shows
  those placeholders: "Plenty of space", "Cache · 0 B" and an empty Projects section.
- Root cause: `frontend/lib/core/files/storage_root.dart:147-156` asks for `AppPermission.storage` before
  it creates a folder the app owns. `frontend/lib/core/permissions/permissions_service.dart:207-208` maps
  that to `Permission.photos`, and `frontend/android/app/src/main/AndroidManifest.xml` declares neither
  `READ_MEDIA_IMAGES` nor `READ_EXTERNAL_STORAGE`. `permission_handler` reports an undeclared permission
  as denied, so `resolve()` fails on every call. App-specific folders need no permission at all.
- Knock-on effects: `StorageGuard.check()` (`frontend/lib/core/files/storage_guard.dart:120-125`) and
  `CacheCleanup.prune()` (`frontend/lib/core/files/cache_cleanup.dart:33-38`) fail the same way. Clear
  cache then shows the import rationale ("Tapture reads photos and files you choose to import.") as its
  error. Every future file write (photos, exports, thumbnails) goes through this root.

## Scope
- Change:
  - `frontend/lib/core/files/storage_root.dart`: remove the permission request from `_StorageRoot._open()`.
    After the review below, remove the `permissions` parameter from `StorageRoot()` and
    `StorageRoot.fake()`, and remove the `_permissions` field. Keep the writability probe and the
    `StorageFailure` it returns.
  - `frontend/test/core/files/storage_root_test.dart`: replace the test "a storage denial is a typed
    failure…" (line 76) as described in the steps.
- Do not change: where the root lives (prompt 004), `AppPermission.storage` and its mapping (import still
  uses it), the `_usageOnly` fallback that web relies on (task 286), or the database location.

## Rules
- FE-STR-11: platform folders stay behind `StorageRoot` in `core/files/`.
- FE-CODE-06: an unwritable or missing folder is still a `StorageFailure` with a recovery action.
- FE-CODE-12: update the one-line docs on `StorageRoot()` and `resolve()`, which still say it "asks
  PermissionsService".
- FE-TEST-03 and FE-TEST-10: use fakes, and keep the unwritable-location failure test.
- FE-SEC-08: Clear cache still prunes `.cache` only.
- Task 235 (permission minimisation): add no permission to the manifest.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening fix-storage-root-on-android "Fix the storage root on Android"`
   (FE-FLOW-08).
2. In `_open()`, delete the `_permissions.request(AppPermission.storage)` block. The root is created,
   `.cache` is ensured, and the probe runs as before.
3. After the review, remove the now-unused `permissions` parameter and field, and the
   `package:tapture/core/permissions/permissions.dart` import if nothing else uses it.
4. Tests in `frontend/test/core/files/storage_root_test.dart`:
   - "resolving the root never asks for a permission": pass a recording fake (or none) and assert the
     tree is created.
   - Keep the idempotence test and the missing and read-only `StorageFailure` tests unchanged.
5. `frontend/test/features/settings/presentation/storage_settings_screen_test.dart`: add "with a
   resolvable root, Storage shows the real cache size". Seed `.cache` with a file of known size under a
   `StorageRoot.fake`, and assert that `Copy.settingsCacheSize` shows that size, not 0 B.

## Human review
⛔ Stop before step 3 and ask:
- `StorageRoot({PermissionsService? permissions})` and `StorageRoot.fake(permissions:)` are public `core/`
  API. Only `storage_root_test.dart:81` passes it. Choose (a) remove the parameter now, or (b) keep it,
  unused, for one release. Recommend (a), because an ignored parameter misleads callers.
Proceed only with an explicit answer. If the answer is "proceed", do (a).

## Acceptance criteria
- [ ] On an Android device, opening Storage creates `Tapture/` and `Tapture/.cache` under the app's
      documents folder, and asks for no permission.
- [ ] Storage shows a real cache size and one row per project folder. It shows neither the generic error
      state nor the placeholder totals.
- [ ] Clear cache confirms, removes only `.cache` content, and shows no error.
- [ ] A read-only or missing location still returns a `StorageFailure` with a recovery action.
- [ ] The Storage screen does not clip at compact, medium or expanded widths, in light, dark or outdoor,
      or at 200 percent text.
- [ ] FBK0000002 is resolved. Moving the folder where a file manager can see it is covered by prompt 004.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- `flutter run -d <android-device>`, then Settings → Storage: real totals, and Clear cache succeeds.
- No goldens change.
