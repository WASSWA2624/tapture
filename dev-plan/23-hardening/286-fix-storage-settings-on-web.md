# 286 — Fix storage settings on web

**Phase** 23 · Hardening  |  **Depends on** [079](../07-account-and-settings/079-settings-shell.md), [285](285-enable-app-database-on-web.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Storage settings loads on web instead of `ProviderFailure`. Usage that needs a `dart:io` tree is empty;
retention still reads and writes through `SettingsStore`. Cache clear does not throw and does not
touch originals.

## Files

- `frontend/lib/features/settings/presentation/storage_settings_screen.dart`
- `frontend/test/features/settings/presentation/storage_settings_screen_test.dart`

## Constraints

- Platform file access stays in `core/files/` (FE-STR-11).
- Clearing cache never deletes originals (FE-SEC-08).
- Native usage totals stay as they are.

## Definition of done

- [ ] On web, Storage is not `AppErrorState`; retention can be cycled.
- [x] Native empty, failure and cache-original tests still pass.
- [x] Tests: a failed `StorageRoot` still shows usage chrome (retention), not the generic provider error.
