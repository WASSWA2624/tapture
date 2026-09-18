# 004 — Soften input placeholder text

**Feedback:** chat request, 19 Sep 2026 (no Feedback ID) · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **Depends on:** none

## Goal
Placeholder text inside empty fields reads quieter than typed values and labels in every field the design
system draws. This covers hint text and the label resting inside an empty field. It holds in light, dark
and outdoor themes and still meets 4.5:1 contrast. Typed text, floating labels, helper text and error text
keep their current strength.

## Evidence
- Chat request, 19 Sep 2026: "let all input placeholders be less strong".
- `screenshots/FBK0000003-2.png`: the empty *Your feedback* field shows its resting label in the same full
  ink as typed text (web, expanded, dark).
- Root cause: `frontend/lib/app/theme/app_theme.dart:119-121` sets `hintStyle`, `labelStyle` and
  `floatingLabelStyle` all to `colors.onSurface`. `AppColors` has no quieter text role
  (`color_tokens.dart:17-33`). Every field inherits this theme: `AppTextField` (`app_text_field.dart:232-234`),
  `AppSearchField` (a label that never floats, `app_search_field.dart:110,123-125`), `AppChoiceField`,
  `AppMultiChoiceField`, `AppDateField`, `AppNumberField`, `AppEmailField` and `AppPhoneField`. None of them
  sets its own hint or label style.

## Scope
- Change:
  - `frontend/lib/app/theme/color_tokens.dart`: add the role
    `onSurfaceMuted`. Its doc reads "Placeholder ink: quieter than [onSurface], still 4.5:1 on every surface".
    Add it to the constructor, `copyWith`, `lerp` and all three palettes:
    - light: `Color(0xFF54656F)`. Measured 5.06:1 on the page, 6.06:1 on surface and 5.40:1 on the field
      fill.
    - dark: `Color(0xFF8696A0)`. Measured 6.10:1, 5.72:1 and 4.68:1.
    - outdoor: `Color(0xFF3B4A54)`. Measured 9.16:1 on white. See Human review.

    Reuse the existing `_outlineLight` and `_outlineDark` swatch constants where the values match.
  - `frontend/lib/app/theme/app_theme.dart`: set `hintStyle` and `labelStyle` to `colors.onSurfaceMuted`.
    Leave `floatingLabelStyle`, typed text and `errorStyle` as they are.
  - `frontend/lib/app/theme/color_swatches.dart`: add the swatch (FE-CONS-03).
- Do not change: typed text, floating labels, helper text, counters, error text, disabled styling, or any
  field widget. Nothing under `lib/features/`.

## Rules
- FE-THEME-11: a new token, not a one-off override. FE-THEME-02: define it in all three modes.
- FE-THEME-04: the name is semantic. FE-THEME-07: style Material centrally in `app_theme.dart`.
- FE-THEME-10 and FE-A11Y-04: 4.5:1 body contrast, measured by test.
- FE-THEME-03: outdoor changes contrast only, never layout.
- FE-TEST-02: goldens for design-system visuals. FE-TEST-06: extend the token test, never weaken it.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening soften-input-placeholder-text "Soften input placeholder text"`
   (FE-FLOW-08).
2. Add `onSurfaceMuted` to `AppColors` in every place listed in Scope.
3. In `frontend/test/design_system/tokens/color_tokens_test.dart`, add the role to `_roles` and add a test:
   "muted text meets 4.5:1 on every surface in every mode".
4. Point `hintStyle` and `labelStyle` at the new role, and add the swatch.
5. In `frontend/test/app/theme/app_theme_test.dart`, assert that hint and resting label use
   `onSurfaceMuted`, and that the floating label and typed text still use `onSurface`, in all three modes.
6. Regenerate only the affected goldens (see Verification).

## Human review
⛔ Stop before step 3 and ask:
- Step 3 adds an assertion to the phase-01 design-token guardrail (task 013). Add it? Recommend yes,
  because it extends the guardrail and does not weaken it (FE-TEST-06, FE-FLOW-07).
- Should the label resting inside an empty field be muted as well as hint text? Recommend yes. In this app
  the resting label is what reads as the placeholder (see FBK0000003-2), and `AppSearchField`'s label never
  floats.
- Outdoor: use `0xFF3B4A54` (9.2:1, still quieter than black), or keep full black because outdoor favours
  contrast (FE-THEME-03)? Recommend `0xFF3B4A54`.
Proceed only with an explicit answer. If the answer is "proceed", do all three recommendations.

## Acceptance criteria
- [ ] Hint text and resting labels use `onSurfaceMuted` in light, dark and outdoor. The floating label and
      typed value still use `onSurface`.
- [ ] `onSurfaceMuted` meets 4.5:1 on background, surface and surfaceVariant in every mode.
- [ ] Every field type listed in Evidence picks up the change, with no edits to field widgets.
- [ ] Nothing moves: the goldens differ only in placeholder colour, at compact, medium and expanded widths
      and at 200 percent text.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- `flutter test --update-goldens test/design_system`. Every changed image must show a swatch, or an empty
  field's hint or resting label. Expect `color_swatches_*`, the field goldens (`app_text_field_*`,
  `app_search_field_*`, `app_choice_field_*`, `app_multi_choice_field_*`, `app_date_field_*`,
  `app_number_field_*`, `app_email_field_*`, `app_phone_field_*`, `app_form_*`), `theme_preview_*`, and any
  gallery or responsive image that contains an empty field. Open any other changed golden. If it has no
  empty field, stop and find the cause. List every regenerated file in the pull request.
