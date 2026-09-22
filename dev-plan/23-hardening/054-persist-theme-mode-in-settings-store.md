# 054 — Persist the theme mode in the settings store

**Phase** 23 · Hardening  |  **Depends on** [003](../03-design-system/003-design-system.md), [007](../07-account-and-settings/007-account-and-settings.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The chosen appearance is stored in the settings store as
`appearance.themeMode`. A one-time read of the old temp-dir file keeps an
upgraded device's choice; that file is never deleted. Nothing on screen
changes.

## Files

- `frontend/lib/features/settings/domain/setting_keys.dart`
- `frontend/lib/app/theme/settings_text_store.dart`
- `frontend/lib/main.dart`
- `frontend/test/app/theme/settings_text_store_test.dart`
- `frontend/test/app/theme/theme_controller_test.dart`

## Constraints

- One source of truth, the settings store (FE-STATE-06). Persist before the
  interface confirms (FE-STATE-07).
- `app/` may read the settings barrel; `core/` must not (FE-STR-04,
  FE-STR-08).
- One public type, named for what it is (FE-STR-06, FE-CODE-03).
- The key name lives in `SettingKeys` only (FE-CODE-09).
- Tests use `SettingsStore.fake()` and `TextStore.memory()` (FE-TEST-03).
- Do not change `AppThemeMode`, how `TaptureApp` resolves the theme,
  `TextStore` itself, the widget gallery's local theme switch, or any
  screen.

## Definition of done

- [x] A written mode round-trips through a new store instance over the
      same fake.
- [x] With the key unset, the legacy value is used once and then written
      through on the next `setMode`.
- [x] A stored value wins over a different legacy value.
- [x] An unknown stored string still decodes to `AppThemeMode.system`.
- [x] Existing geometry and theme tests still pass.
