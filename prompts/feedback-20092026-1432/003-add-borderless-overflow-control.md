# 003 — Add a borderless overflow control

**Feedback:** FBK0000006 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **Depends on:** —

## Goal
`AppOverflowMenu` gains an `outlined` flag, matching `AppIconButton`, so a three-dot control inside a
list row can drop its box and still read as a control — noticeable at rest, and clearly hovered, focused
and pressed. The outlined form stays the default, so every existing use is unchanged. Correct in light,
dark and outdoor, at every width, and at 200 percent text.

## Evidence
- FBK0000006: the reporter asks that each project row carry a three-dot more button with "no border, but
  visually noticeable". `screenshots/FBK0000006.png` shows the row's control drawn as an outlined box,
  the same weight as the app-bar control beside it, so the row reads as two equal buttons. Web, desktop,
  expanded, landscape, light, text scale 1.
- Root cause: `frontend/lib/app/theme/app_theme.dart:90-102` gives every `IconButton` `side: outline`
  centrally (FE-THEME-07), and `AppOverflowMenu`
  (`frontend/lib/core/widgets/app_overflow_menu.dart:28-60`) passes no style, so it inherits the box.
  `AppIconButton` already solves this with `outlined`
  (`frontend/lib/core/widgets/app_icon_button.dart:38-52`); the overflow control has no equivalent.

## Scope
- Change:
  - `frontend/lib/core/widgets/app_overflow_menu.dart`: add `bool outlined = true`; when false, pass a
    `style` with `side: BorderSide.none` and keep the 48 dp target, the token icon size, the semantic
    label and the tooltip. Mirror `AppIconButton`'s doc comment wording.
  - `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`: add the borderless variant beside
    the existing `AppOverflowMenu` entry at `:427`, in every state (rest, hover, focus, pressed,
    disabled), so the component exists as far as other features are concerned (FE-CONS-03).
  - Goldens for both variants in light, dark and outdoor.
- Do not change: the default, the menu sheet, `showAppOverflowActions`, `AppIconButton`, the central
  `iconButtonTheme`, or any call site. Adopting the flag on the project row is 006's work.

## Rules
- FE-CONS-01 and FE-CONS-02: extend the catalogue widget; do not fork a second three-dot control.
- FE-CONS-03: the gallery entry ships with the change.
- FE-THEME-01 and FE-THEME-11: tokens only — hover, focus and pressed come from token surfaces, never a
  literal `Color` or `EdgeInsets`. If the rest state needs a tone that does not exist, add a token.
- FE-THEME-06: separate by tone and outline, not shadow.
- FE-THEME-03 and FE-THEME-10: outdoor changes contrast, not geometry; the borderless form still meets
  3:1 for its interactive outline or focus ring in all three themes.
- FE-A11Y-01, FE-A11Y-02 and FE-A11Y-06: 48 dp, a required label and tooltip, and a focus indicator that
  is visible without the border.
- FE-TEST-02 and FE-A11Y-10: design-system widgets ship goldens in light, dark and outdoor, and the
  widget tests use the accessibility matchers.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 03-design-system add-borderless-overflow-control "Add a borderless overflow control"`
   (FE-FLOW-08).
2. Add the flag and its style, keeping the default path byte-identical in output.
3. Add the gallery entry in every state.
4. Tests:
   - `frontend/test/core/widgets/app_overflow_menu_test.dart`: the default still paints a border; with
     `outlined: false` it paints none; both keep a 48 dp target, the label and the tooltip; the menu
     opens and selects the same way in both.
   - A focus-traversal test asserting a visible focus indicator on the borderless variant.
   - Goldens: both variants, light, dark and outdoor, at default and 200 percent text.
   - Confirm the existing golden set for every current `AppOverflowMenu` call site is unchanged.

## Human review
⛔ Stop before step 2 and ask:
- "No border, but visually noticeable" leaves the rest state open. Should the borderless control sit on
  a faint token surface tint at rest, or be bare ink at rest and take a tonal surface only on hover,
  focus and press? **Recommendation: bare ink at rest, tonal surface on hover, focus and press**, which
  keeps rows quiet, matches `AppIconButton(outlined: false)`, and still meets FE-THEME-10 because the
  glyph itself carries the contrast.

Proceed only with an explicit answer. If the answer is "proceed", do the recommendation.

## Acceptance criteria
- [ ] `AppOverflowMenu()` with no arguments renders exactly as it does today at every existing call site.
- [ ] `AppOverflowMenu(outlined: false)` renders no border, keeps a 48 dp target, and opens the same menu.
- [ ] The borderless variant shows a visible hover, focus and pressed state in light, dark and outdoor.
- [ ] Both variants pass the label, tooltip, target-size and contrast matchers in all three themes.
- [ ] Both variants appear in the widget gallery in every state.
- [ ] Nothing clips at 200 percent text at 400, 800 and 1200 dp.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Regenerate goldens with `--update-goldens` only for `app_overflow_menu` and the gallery, and list the
  files regenerated. No other golden may change; a change elsewhere means the default was altered.
