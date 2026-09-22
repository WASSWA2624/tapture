# 058 — Show a collapse icon on the feedback form

**Phase** 23 · Hardening  |  **Depends on** [037](037-add-feedback-close-control.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The control that folds Give us feedback into its bar looks and reads as collapse, not close. The bar's
control that discards the draft says so. An X then means one thing across the feedback surfaces.

## Files

- `frontend/lib/features/feedback/presentation/give_feedback_screen.dart`
- `frontend/lib/features/feedback/presentation/feedback_draft_bar.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`
- `frontend/test/core/copy/copy_test.dart`

## Constraints

- One icon per concept: collapse and expand are a pair, and X means close or discard (FE-CONS-08).
- The semantic label says what the control does (FE-A11Y-02).
- Plain language; labels live in `Copy` (FE-SIMP-10, FE-L10N-01).
- 48 dp, unchanged (FE-A11Y-01).
- Icons from the one Material family at token size (FE-THEME-08).
- Do not change fold, expand or discard behaviour; the discard confirmation; the Close controls of
  Download feedback and Delete feedback; or the floating menu.

## Definition of done

- [x] The form's top-start control shows a collapse icon, and a screen reader hears "Continue later".
- [x] Tapping it folds the form into the bar with the text and images kept.
- [x] The bar's X is announced as "Discard draft" and still confirms before clearing.
- [x] The tip on the form names "Continue later".
- [x] Tests: the form's leading control has the label "Continue later", uses `Icons.close_fullscreen`,
      and folds the draft with its text kept; the bar's X has the label "Discard draft" and still asks
      before discarding; Download and Delete Close finders stay as they are.
