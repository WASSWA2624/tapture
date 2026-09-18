# 001 — Enable AppDatabase on web

**Feedback:** FBK0000003 · **Type:** Defect · **Priority:** P1 · **Effort:** L · **Depends on:** —

## Goal
On Flutter web (Chrome, expanded, dark), Operator and Capture under Settings load and save instead of
`AppErrorState` ("A service this screen uses failed."). A reload keeps the operator name and capture
defaults.

## Evidence
- FBK0000003: Operator, Capture and Storage fail on web; Operator shows the error without Try again.
  Web, desktop, expanded, landscape, system (dark), text scale 1, app 1.0.0.
- Screenshot 2: Operator, generic `ProviderFailure`, no retry.
- Root cause: `frontend/lib/core/db/app_database_stub.dart:9` throws
  `UnsupportedError('AppDatabase.open is not available on web')`.
  `operator_profile_screen.dart` `_database()` and `capture_settings_screen.dart` `_store()` call
  `AppDatabase.open()`. `Failure.from` maps that to `ProviderFailure`.
- Operator omits `onRetry` on `AsyncValueView`; Capture already passes it.

## Scope
- Change: `app_database.dart` conditional import (same shape as `blob_store.dart`: `stub` /
  `dart.library.io` / `dart.library.js_interop`); new `app_database_web.dart` using
  `package:drift/wasm.dart` `WasmDatabase.open`; `web/sqlite3.wasm` and the Drift worker; WAL/FK
  setup equivalent to `app_database_io.dart`; Operator `onRetry`.
- Do not change: native `app_database_io.dart`; schema or migrations; encrypted `encryptionKey` on
  web (064 stays native — ignore or fail with `StorageFailure`); Capture/Operator UI.

## Rules
- FE-STATE-07: persist before the screen confirms; in-memory-only is not enough.
- FE-STR-11: wasm URIs live in the db opener, not in screens.
- FE-CODE-06, FE-CONS-04, FE-CONS-11: failures stay `Failure` / `AppErrorState`.
- FE-FLOW-06: no new pub package if `drift` 2.31 and `sqlite3` 2.9.4 already cover wasm.
- FE-TEST-01, FE-TEST-03, FE-TEST-10.

## Steps
1. Record the work: `cd frontend && dart run tool/new_task.dart 23-hardening enable-app-database-on-web "Enable AppDatabase on web"`.
2. Replace the stub throw with a web executor that opens a named database (`tapture.db`) through
   `WasmDatabase.open`, `sqlite3Uri` + `driftWorkerUri` under `web/`. `openMemoryExecutor` uses
   `WasmDatabase.inMemory`.
3. Copy `sqlite3.wasm` (sqlite3.dart release matching 2.9.4) and the Drift worker into `web/`.
4. Pass `onRetry: () => ref.invalidate(operatorProfileProvider)` on Operator's `AsyncValueView`.
5. Tests: web suite that `AppDatabase.open()` then `AppDatabase.open()` again reads a written
   device-profile row; Operator still has loading/error/save tests; add retry on the failure path.
   Skip wasm I/O on VM (`kIsWeb`).

## Human review
⛔ Stop before step 2 and ask:
- Persist with `WasmDatabase.open` + `web/sqlite3.wasm` + Drift worker (recommended), or in-memory
  only (Operator/Capture reset on reload, breaks FE-STATE-07)?
Proceed only with an explicit answer. If the answer is "proceed", do the recommended persist path.

## Acceptance criteria
- [ ] On web, Operator shows the name/initials/contact form, not `ProviderFailure`.
- [ ] On web, Capture shows camera/dates/GPS/quality/folder/naming rows.
- [ ] Reloading the page restores the last saved operator and capture defaults.
- [ ] Native `AppDatabase.open` / WAL / encryption behaviour is unchanged.
- [ ] Operator error state offers Try again, matching Capture and Storage.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Manual: Chrome, `/more/operator` and `/more/capture`, save, reload.
- No goldens.
