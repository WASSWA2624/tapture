# 007 — Persist the theme mode in the settings store

**Feedback:** FBK0000003 · **Type:** Gap · **Priority:** P5 · **Effort:** S · **Depends on:** —

## Goal
The chosen appearance (system, light, dark or outdoor) is stored durably in the settings store. It
survives a restart, a system "clear cache" and, on the web, a reload, and it still applies before the
first frame. This prepares the Appearance control in 008. Nothing on screen changes here.

## Evidence
- FBK0000003: the reporter asks for tools in Settings to change the theme. `screenshots/FBK0000003.png`
  shows the Settings list with no appearance entry. Android, mobile, compact, portrait, system dark.
- A theme control is only useful if it remembers the choice. Task 031's Definition of done requires "The
  chosen mode survives a restart". Today `ThemeModeController()` uses `TextStore.file()`
  (`frontend/lib/app/theme/theme_controller.dart:29`), and that writes to `Directory.systemTemp`
  (`frontend/lib/core/files/text_store_io.dart:7-14`, which is documented as "until the settings store
  exists").
- On Android the temp folder is the app cache, which the system may clear. On the web
  `text_store_stub.dart` stores nothing.
- The settings store now exists, and `main.dart` already opens one before `runApp`
  (`frontend/lib/main.dart:50` and `:108-124`).

## Scope
- Change:
  - `frontend/lib/features/settings/domain/setting_keys.dart`: add `themeMode`
    (`'appearance.themeMode'`, default `'system'`), and list it in `names`.
  - `frontend/lib/app/theme/settings_text_store.dart` (new): `SettingsTextStore implements TextStore`
    over a `SettingsStore` and `SettingKeys.themeMode`. It reads the legacy `TextStore.file()` value
    once when the key is unset, and never deletes that file.
  - `frontend/lib/main.dart`: override `themeModeProvider` with
    `ThemeModeController.withStore(SettingsTextStore(...))`, using the store opened before `runApp`.
  - Tests: `frontend/test/app/theme/settings_text_store_test.dart` (new) and
    `frontend/test/app/theme/theme_controller_test.dart`.
- Do not change: `AppThemeMode`, how `TaptureApp` resolves the theme, `TextStore` itself, the widget
  gallery's local theme switch, or any screen.

## Rules
- FE-STATE-06: one source of truth, the settings store. FE-STATE-07: persist before the interface
  confirms (`setMode` already awaits the write).
- FE-STR-04 and FE-STR-08: `app/` may read the settings barrel, and `core/` must not.
- FE-STR-06 and FE-CODE-03: one public type, with a name that says what it is.
- FE-CODE-09: the key name lives in `SettingKeys` only.
- FE-TEST-03: `SettingsStore.fake()` and `TextStore.memory()` in tests.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening persist-theme-mode-in-settings-store "Persist the theme mode in the settings store"`
   (FE-FLOW-08).
2. Add the key.
3. Add `SettingsTextStore`: `read()` returns the stored value, or the legacy value, or null. `write()`
   writes the key.
4. Override `themeModeProvider` in `main.dart`, including when the store fell back to a fake (the
   behaviour is then as today).
5. Tests:
   - a written mode round-trips through a new store instance over the same fake;
   - with the key unset, the legacy value is used once and then written through on the next `setMode`;
   - a stored value wins over a different legacy value;
   - an unknown stored string still decodes to `AppThemeMode.system`;
   - the existing geometry and theme tests still pass.

## Human review
⛔ Stop before step 3 and ask:
- Where should the preference live? (a) the settings store, as `appearance.themeMode`, with a one-time
  read of the old temp file, which is left in place; or (b) keep `TextStore.file()` but move its file to
  the application support folder, which still stores nothing on the web. Recommend (a).
Proceed only with an explicit answer. If the answer is "proceed", do (a).

## Acceptance criteria
- [ ] Android: choose a mode (through a test hook or 008), clear the app's cache in system settings,
      reopen the app, and the mode is kept.
- [ ] Web: the mode survives a reload wherever the settings store opens.
- [ ] Restarting shows the chosen theme on the first frame, with no flash of another theme.
- [ ] A device that saved a mode under the old temp file keeps it after upgrading.
- [ ] FBK0000003 is resolved together with 008.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- No goldens change.
