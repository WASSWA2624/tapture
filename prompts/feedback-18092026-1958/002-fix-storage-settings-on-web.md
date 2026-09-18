# 002 — Fix storage settings on web

**Feedback:** FBK0000003 · **Type:** Defect · **Priority:** P1 · **Effort:** M · **Depends on:** 001

## Goal
On Flutter web, Storage under Settings loads instead of `AppErrorState`. Retention still saves.
Usage totals that need a `dart:io` tree show empty on web rather than crashing. Light, dark and
outdoor, compact through expanded, 200 percent text.

## Evidence
- FBK0000003: Storage fails on the same web desktop session as Operator. Screenshot 3: Storage,
  same `ProviderFailure`, with Try again (`onRetry` already set).
- Root cause, after 001: `storage_settings_screen.dart` still imports `dart:io` and `_load()` calls
  `StorageRoot.resolve()` (`storage_root.dart`), which creates `Directory` via path_provider. That
  API is native. `_settings()` also used `AppDatabase.open()` (001).
- Do not treat a generic retry as the fix; retrying the same native tree still fails.

## Scope
- Change: `_StorageSettings._load` so a missing web file tree does not throw. Retention continues
  through `SettingsStore` (001). Clear cache on web is a no-op success or a typed `StorageFailure`
  with recovery copy, not a crash. Prefer wrapping the walk behind `StorageRoot` rather than
  `kIsWeb` in the screen (FE-STR-11).
- Do not change: native usage totals, cache prune of originals (FE-SEC-08), Capture/Operator,
  `FileWriter` photo storage.

## Rules
- FE-STR-11: platform file access stays in `core/files/`.
- FE-CONS-04: loading / empty / error still go through `AsyncValueView`.
- FE-SEC-08: clearing cache must not delete originals (already tested).
- FE-L10N-01: any new empty copy goes in `Copy`.
- FE-TEST-01, FE-TEST-10.

## Steps
1. Extend the 001 plan task, or
   `cd frontend && dart run tool/new_task.dart 23-hardening fix-storage-settings-on-web "Fix storage settings on web"`.
2. Make `StorageRoot.resolve` return a `StorageFailure` (or an empty virtual root) on web instead of
   throwing through `dart:io`.
3. In `_load`, on that failure: keep `headroom: HeadroomState.ample`, `projects: []`,
   `cacheBytes: 0`, `retentionDays` from the store. Do not `throw _asError`.
4. Clear cache: if there is no `.cache` directory, succeed with 0 bytes reclaimed.
5. Tests: existing empty/failure/cache-original tests stay green; a web/fake-root case shows the
   empty state or the usage list with 0 bytes, never `AppErrorState`; cycling retention still writes
   `SettingKeys.retentionDays`.

## Human review
⛔ Stop before step 2 and ask:
- Empty usage on web plus working retention (recommended), or a full IndexedDB/OPFS project tree
  (new file-storage platform, larger than this prompt)?
Proceed only with an explicit answer. If the answer is "proceed", do empty usage plus retention.

## Acceptance criteria
- [ ] On web, Storage is not `ProviderFailure`.
- [ ] Retention can be cycled and survives a reload (depends on 001).
- [ ] Native storage totals and "clear cache does not delete originals" still pass.
- [ ] Compact, medium, expanded; light, dark, outdoor; 200 percent text still fit (FE-RESP-10,
      FE-A11Y-03).

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Manual: Chrome, `/more/storage`.
- No goldens unless empty-state copy changes a catalogue widget.
