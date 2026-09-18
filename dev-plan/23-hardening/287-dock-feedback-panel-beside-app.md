# 287 — Dock feedback panel beside app

**Phase** 23 · Hardening  |  **Depends on** [283](283-feedback-dictation-and-layout.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On expanded windows, Give us feedback is a trailing column beside the app. The screen in action is not
covered by the panel. Compact and medium still fill the overlay.

## Files

- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

## Constraints

- Size class from `context.sizeClass` (FE-RESP-02). Trailing edge, not left/right (FE-L10N-05).
- Panel width from `AppConstants.userFeedback.panelWidth` (FE-CODE-09).
- Screenshots still capture the app child only.

## Definition of done

- [x] Expanded: the app's right edge is at or left of the panel; taps on the app hit the app.
- [x] Compact and medium still fill with the form; the FAB hides while expanded.
- [x] Tests: `App screen` aligned to the trailing edge must sit beside, not under, the form.
