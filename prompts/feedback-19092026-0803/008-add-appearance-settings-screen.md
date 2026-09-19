# 008 — Add the Appearance settings screen

**Feedback:** FBK0000003 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **Depends on:** 007

## Goal
Settings gains an **Appearance** entry that opens a screen to choose System, Light, Dark or Outdoor. The
app changes theme at once, without a restart, and keeps the choice (007). The screen works at compact,
medium and expanded widths, in portrait and landscape, and at 200 percent text.

## Evidence
- FBK0000003: the reporter asks for theme-changing tools in Settings. `screenshots/FBK0000003.png`
  shows the Settings list (Operator, Capture, AI, Language, Storage, Files, Security, About) with no
  appearance entry. Android, mobile, compact, portrait, system dark.
- The controller exists, but nothing lets a person use it. `ThemeModeController.setMode`
  (`frontend/lib/app/theme/theme_controller.dart:40-43`) has no caller in `lib/`; the gallery keeps its
  own local switch. Task 031 left "the settings screen control that changes the mode" to the settings
  phase (`dev-plan/03-design-system/031-theme-assembly.md`, Out of scope), and task 079 did not add it
  (`frontend/lib/features/settings/presentation/settings_screen.dart:122-159`).
- FE-SIMP-12 reason for a new setting: no system setting can pick the outdoor high-contrast theme
  (`app-write-up.md` §58, FE-THEME-02), and field work needs it in direct sun.

## Scope
- Change:
  - `frontend/lib/app/router.dart`: add `AppRoutes.settingsAppearance` (`'$more/appearance'`) and a
    `GoRoute(path: 'appearance')` beside `storage` (around line 216).
  - `frontend/lib/features/settings/presentation/appearance_settings_screen.dart` (new): an `AppPage`
    with a vertical `AppRadioGroup<AppThemeMode>` bound to `themeModeProvider`, calling `setMode` on
    change.
  - `frontend/lib/features/settings/presentation/presentation.dart`: export it.
  - `settings_screen.dart`: add an `_appearanceRoute` constant and a section after Language.
  - `frontend/lib/app/feedback_host.dart`: map the new path in `_screenName` and `_routeName`, so
    feedback from this screen is labelled.
  - `frontend/lib/core/copy/copy.dart`: `settingsAppearanceTitle`, `settingsAppearanceSubtitle` and four
    option labels (`themeModeSystem`, `themeModeLight`, `themeModeDark`, `themeModeOutdoor`).
  - Tests, listed in the steps.
- Do not change: `AppThemeMode`, the token values or themes, persistence (007), the gallery switch, or
  any other settings section.

## Rules
- FE-CONS-01: reuse `AppPage`, `AppRadioGroup` and `AppListTile`; build no new picker.
- FE-STATE-04: the screen calls `setMode`, and holds no logic.
- FE-THEME-02 and FE-THEME-03: every mode uses one token set, and outdoor changes contrast only.
- FE-SIMP-05 and FE-SIMP-12: the default stays System, and the reason is recorded in the task.
- FE-L10N-01 and FE-L10N-02: labels live in `Copy`, and keys name meaning.
- FE-L10N-10: the change applies live without losing in-progress input.
- FE-A11Y-01, FE-A11Y-02 and FE-A11Y-05: 48 dp, labelled, and the selection is shown by the radio mark as
  well as colour.
- FE-RESP-10 and FE-A11Y-03: three widths, two orientations, and 200 percent text.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening add-appearance-settings-screen "Add the Appearance settings screen"`
   (FE-FLOW-08). State the FE-SIMP-12 reason in the task.
2. Add the copy, the screen, the route and the settings section.
3. Map the path in `feedback_host.dart`.
4. Tests:
   - `frontend/test/features/settings/presentation/appearance_settings_screen_test.dart` (new): four
     options; System is selected by default; choosing Dark updates `themeModeProvider` and a new
     controller over the same `TextStore.memory()` restores it; no overflow at 360, 700 and 1280 dp, in
     portrait and landscape, at 100 and 200 percent text; the 48 dp and label matchers pass.
   - `frontend/test/features/settings/presentation/settings_screen_test.dart`: Appearance follows
     Language and navigates to the new route.
   - `frontend/test/app/router_test.dart`: `/more/appearance` builds the screen.
   - `frontend/test/core/copy/copy_test.dart` for the new keys.

## Human review
⛔ Stop before step 2 and ask:
- Placement: (a) a new **Appearance** section after Language, or (b) a tile directly under Stay offline
  for quick field access? Recommend (a), because the settings list is one tile per section.
- Options: offer all four (System, Light, Dark, Outdoor), with Outdoor still following the device's
  light or dark? Recommend yes.
Proceed only with an explicit answer. If the answer is "proceed", do (a) with all four options.

## Acceptance criteria
- [ ] Settings shows Appearance after Language on every width, and tapping it opens the screen.
- [ ] Choosing Light, Dark, Outdoor or System re-themes the whole app at once, including the shell and
      the feedback overlay, without a restart or lost input.
- [ ] The choice is still active after restarting the app (with 007).
- [ ] No clipping at 360 dp, in landscape or at 200 percent text, in light, dark and outdoor.
- [ ] Feedback sent from this screen names it "Appearance" with route name `settingsAppearance`.
- [ ] FBK0000003 is resolved.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- On an Android phone: Settings → Appearance → Outdoor; the app switches at once and keeps it after a
  restart.
- No goldens change.
