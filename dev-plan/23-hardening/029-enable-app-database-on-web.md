# 029 — Enable AppDatabase on web

**Phase** 23 · Hardening  |  **Depends on** [004](../04-data-layer/004-local-database.md), [007](../07-account-and-settings/007-account-and-settings.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

`AppDatabase.open` and `AppDatabase.memory` work in the browser through Drift's wasm opener, so Operator
and Capture settings load and persist across a reload instead of throwing `UnsupportedError`.

## Files

- `frontend/lib/core/db/app_database.dart` (conditional import)
- `frontend/lib/core/db/app_database_web.dart` (new)
- `frontend/lib/core/db/app_database_stub.dart`
- `frontend/web/sqlite3.wasm`, `frontend/web/drift_worker.js` (new)
- `frontend/lib/features/settings/presentation/operator_profile_screen.dart`

## Constraints

- Native WAL/encryption in `app_database_io.dart` does not change.
- No new pub package if `drift` 2.31 and `sqlite3` 2.9.4 already provide wasm (FE-FLOW-06).
- Writes persist (FE-STATE-07). In-memory-only is not enough.
- Encryption remains native (064); `encryptionKey` on web is ignored.

## Definition of done

- [ ] On web, Operator and Capture settings load and save; a reload restores them.
- [x] Operator's error state offers Try again.
- [x] Native open/memory tests still pass.
- [x] Tests: retry on Operator failure; the web opener is wired and `web/sqlite3.wasm` plus `web/drift_worker.js` are present.
