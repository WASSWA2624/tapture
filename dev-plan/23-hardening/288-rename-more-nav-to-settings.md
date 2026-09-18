# 288 — Rename More nav to Settings

**Phase** 23 · Hardening  |  **Depends on** [073](../06-app-shell/073-nav-shell.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The fourth shell destination, already a settings cog, is labelled Settings. Routes stay `/more`.

## Files

- `frontend/lib/core/copy/copy.dart`
- `frontend/.rules/06-simplicity.md`
- `frontend/lib/app/nav_shell.dart`, `frontend/lib/app/router.dart`, `frontend/lib/app/feedback_host.dart`
- `frontend/lib/features/settings/presentation/settings_screen.dart`
- `frontend/test/app/nav_shell_test.dart`

## Constraints

- Four destinations, no fifth (FE-SIMP-02). Visible strings on `Copy` (FE-L10N-01).
- Do not rename `AppRoutes.more` or `/more/…` paths.

## Definition of done

- [x] Compact bar, medium rail and expanded rail say Settings for destination 3.
- [x] `/more/operator` and the settings root still resolve.
- [x] Tests: `nav_shell_test` still matches `Copy.navMore`, now `'Settings'`.
