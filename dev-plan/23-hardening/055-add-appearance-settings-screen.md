# 055 — Add the Appearance settings screen

**Phase** 23 · Hardening  |  **Depends on** [003](../03-design-system/003-design-system.md), [007](../07-account-and-settings/007-account-and-settings.md), [054](054-persist-theme-mode-in-settings-store.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Settings gains an Appearance entry after Language. The screen offers System,
Light, Dark and Outdoor. The app re-themes at once and keeps the choice
through the settings store (task 310).

No system setting can pick the outdoor high-contrast theme, and field work
needs it in direct sun (FE-SIMP-12, FE-THEME-02).

## Files

- `frontend/lib/app/router.dart`
- `frontend/lib/app/feedback_host.dart`
- `frontend/lib/features/settings/presentation/appearance_settings_screen.dart`
- `frontend/lib/features/settings/presentation/presentation.dart`
- `frontend/lib/features/settings/presentation/settings_screen.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/features/settings/presentation/appearance_settings_screen_test.dart`
- `frontend/test/features/settings/presentation/settings_screen_test.dart`
- `frontend/test/app/router_test.dart`
- `frontend/test/core/copy/copy_test.dart`

## Constraints

- Reuse `AppPage`, `AppRadioGroup` and `AppListTile` (FE-CONS-01).
- The screen calls `setMode` and holds no logic (FE-STATE-04).
- Every mode uses one token set; outdoor changes contrast only
  (FE-THEME-02, FE-THEME-03).
- Default stays System (FE-SIMP-05).
- Labels live in `Copy` (FE-L10N-01, FE-L10N-02).
- The change applies live without losing in-progress input (FE-L10N-10).
- 48 dp, labelled, selection shown by the radio mark (FE-A11Y-01,
  FE-A11Y-02, FE-A11Y-05).
- Three widths, two orientations, 200 percent text (FE-RESP-10, FE-A11Y-03).
- Do not change `AppThemeMode`, token values or themes, persistence, the
  gallery switch, or any other settings section.

## Definition of done

- [x] Settings shows Appearance after Language, and tapping it opens the
      screen.
- [x] Four options; System is selected by default; choosing Dark updates
      `themeModeProvider` and a new controller over the same memory store
      restores it.
- [x] No overflow at 360, 700 and 1280 dp, portrait and landscape, 100 and
      200 percent text; 48 dp and label matchers pass.
- [x] `/more/appearance` builds the screen. Feedback names it Appearance
      with route name `settingsAppearance`.
