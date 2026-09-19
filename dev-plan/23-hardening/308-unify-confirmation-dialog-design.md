# 308 — Unify the confirmation dialog design

**Phase** 23 · Hardening  |  **Depends on** [041](../03-design-system/041-app-dialog-service.md), [282](282-in-app-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Every confirmation uses one catalogue design at every width: capped at
`Sizes.dialogMaxWidth` on tablets and desktops, and full width less the
standard inset on phones. Destructive confirmations carry a warning icon as
well as colour. The feedback feature defines its discard-draft confirmation
once.

## Files

- `frontend/lib/app/theme/sizes.dart`
- `frontend/lib/core/widgets/feedback/app_dialog.dart`
- `frontend/lib/features/feedback/presentation/feedback_confirmations.dart`
- `frontend/lib/features/feedback/presentation/feedback_draft_bar.dart`
- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/lib/features/feedback/presentation/give_feedback_screen.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/core/widgets/feedback/app_dialog_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`
- `frontend/test/design_system/tokens/dimensions_test.dart`

## Constraints

- One dialog API; confirmations look the same in every feature (FE-CONS-05).
- Tokens only; the new width is `Sizes.dialogMaxWidth` (FE-THEME-01).
- Danger carries an icon and text as well as colour (FE-THEME-05, FE-A11Y-05).
- Name the consequence and the count; Cancel is the safe default (FE-SIMP-07).
- New strings live in `Copy`; plurals use ICU (FE-L10N-01, FE-L10N-03).
- Capped width, 48 dp buttons, no clipping at 200 percent (FE-RESP-04,
  FE-A11Y-01, FE-A11Y-03).
- Do not change the `showAppConfirm` and `showAppAlert` signatures, the
  delete confirmation copy, the browser leave-page prompt, `AppPanelDialog`,
  or undo.

## Definition of done

- [x] At 1280 dp every confirmation is at most 560 dp wide and centred. At
      360 dp it fills the width less 24 dp each side.
- [x] Destructive confirmations show `Icons.warning_amber_outlined` in
      `danger` beside the title. Buttons stay an end-aligned wrapping row.
- [x] Discard draft (bar, form, desktop exit) uses
      `confirmDiscardFeedbackDraft` with title "Discard this feedback?" and
      a counted message.
- [x] Tests: width and inset; 200 percent; destructive icon present and
      absent; copy at zero, one and many; the three discard surfaces.
- [x] Dialog goldens regenerated in light, dark and outdoor.
