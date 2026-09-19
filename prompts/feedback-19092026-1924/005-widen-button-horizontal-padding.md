# 005 — Widen button horizontal padding

**Feedback:** FBK0000011 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **Depends on:** —

## Goal
Every labelled button (filled, outlined and text) keeps a comfortable gap between its label and its
outline, so no label touches the edge. Icon buttons are unchanged. This holds in light, dark and outdoor,
at compact, medium and expanded widths, and at 200 percent text.

## Evidence
- FBK0000011 (in part): the horizontal padding of "Create a project" and "Import a bundle" is too small.
  `screenshots/FBK0000011.png` (light) and `FBK0000012.png` (dark) show both labels nearly touching
  their outlines. Android, mobile, compact, portrait.
- Root cause: the shared `controlStyle` in `frontend/lib/app/theme/app_theme.dart:28-39` gives every
  filled, outlined and text button `EdgeInsets.symmetric(horizontal: Space.x1, …)`, which is 4 dp. The
  filled, outlined and text themes all copy it (`:70-88`). Icon buttons have their own style (`:90-99`).

## Scope
- Change:
  - `app_theme.dart`: set the `controlStyle` horizontal padding to the token chosen in the review (default
    `Space.x4`). The vertical padding, minimum size, shape and icon-button style stay as they are.
  - `frontend/test/app/theme/app_theme_test.dart`: assert the horizontal padding for filled, outlined
    and text buttons, and keep the outdoor geometry test (`:35`) passing.
  - Goldens, as listed in Verification.
- Do not change: `AppIconButton`, the floating Feedback button, `AppPrimaryAction`'s full-width layout,
  button height, radius or text style.

## Rules
- FE-THEME-07: style Material once, in `app_theme.dart`; no per-screen padding.
- FE-THEME-01 and FE-THEME-11: a token value, never a literal.
- FE-THEME-03: outdoor keeps identical geometry.
- FE-A11Y-01 and FE-A11Y-03: 48 dp targets, and labels wrap rather than clip at 200 percent.
- FE-L10N-06: labels 35 percent longer still fit.
- FE-CONS-03 and FE-TEST-02: regenerate the catalogue goldens in all three themes.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 03-design-system widen-button-horizontal-padding "Widen button horizontal padding"`
   (FE-FLOW-08).
2. Change the padding token in `controlStyle`.
3. Add the theme assertions, and a widget test that a long `AppButton` label at 360 dp and 200 percent
   text wraps without overflow.
4. Regenerate the affected goldens.

## Human review
⛔ Stop before step 2 and ask:
- This changes every labelled button in the app, which commit `0470357` standardised. Which horizontal
  padding: `Space.x3` (12 dp) or `Space.x4` (16 dp)? Recommend `Space.x4`, the Material default for
  labelled buttons.
Proceed only with an explicit answer. If the answer is "proceed", use `Space.x4`.

## Acceptance criteria
- [ ] Filled, outlined and text buttons have 16 dp (or the chosen token) between the label and each side.
- [ ] "Create a project" on the empty Projects list no longer touches its outline, in light, dark and
      outdoor.
- [ ] Buttons in dialogs, forms, empty states and footers still fit at 360 dp and 200 percent text.
- [ ] Icon buttons and the floating button are pixel-identical to before.
- [ ] Light and outdoor share geometry.
- [ ] FBK0000011's padding part is resolved. The label is 002 and the checkbox is 007.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Regenerate with `--update-goldens` only the goldens that draw a labelled button: at least
  `app_button_*`, `app_dialog_*`, `app_empty_state_*`, `app_error_state_*` and `app_form_*` under
  `frontend/test/design_system/`, plus any others the run reports. List every file regenerated.
