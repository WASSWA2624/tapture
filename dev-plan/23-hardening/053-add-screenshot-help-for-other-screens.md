# 053 — Add screenshot help for other screens

**Phase** 23 · Hardening  |  **Depends on** [026](026-in-app-feedback.md), [037](037-add-feedback-close-control.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On a phone or tablet, the folded feedback bar offers Screenshot current
screen in one tap, and the form explains both routes when the platform
cannot capture other windows. No MediaProjection plugin is added.

## Files

- `frontend/lib/features/feedback/presentation/feedback_draft_bar.dart`
- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/lib/features/feedback/presentation/feedback_shots.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

## Constraints

- Reuse `AppIconButton` and the menu's screenshot icon (FE-CONS-01,
  FE-CONS-08).
- Plain language that names the next action (FE-SIMP-10, FE-SIMP-11).
- Strings in `Copy`, with room for 35 percent longer text (FE-L10N-01,
  FE-L10N-06).
- 48 dp and labelled; the result is announced by the existing snack
  (FE-A11Y-01, FE-A11Y-02, FE-A11Y-07).
- A still is taken only when the operator taps (FE-SEC-07).
- The bar calls a callback and keeps no capture logic (FE-STATE-04).
- No overflow at 360 dp (FE-RESP-06).
- Do not change Close, the floating menu, web window sharing, the image
  cap, `Copy.feedbackContinueLater`, or `Copy.feedbackDraftBarHint`.

## Definition of done

- [x] The folded bar's Screenshot current screen adds one image and shows
      `Copy.feedbackShotAdded`.
- [x] Both tips show when `canCapture` is false; neither shows when it is
      true.
- [x] The bar has no overflow at 360 dp with an image count, at 100 and
      200 percent text.
- [x] The new control meets the 48 dp and label matchers.
