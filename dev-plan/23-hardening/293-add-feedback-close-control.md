# 293 — Add feedback close control

**Phase** 23 · Hardening  |  **Depends on** [282](282-in-app-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Give us feedback, Download feedback, Delete feedback, and the folded draft
bar each have one labelled Close. Form Close folds and keeps the draft.
Bar Close confirms discard. Download and Delete Close pop the route.

## Files

- `frontend/lib/features/feedback/presentation/give_feedback_screen.dart`
- `frontend/lib/features/feedback/presentation/download_feedback_screen.dart`
- `frontend/lib/features/feedback/presentation/delete_feedback_screen.dart`
- `frontend/lib/features/feedback/presentation/feedback_draft_bar.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`
- `frontend/test/features/feedback/presentation/download_feedback_screen_test.dart`
- `frontend/test/features/feedback/presentation/delete_feedback_screen_test.dart`

## Constraints

- One close, not back and close both (FE-SIMP-01).
- Discarding the draft still uses `showAppConfirm` with
  `Copy.feedbackDiscardDraft` (FE-SIMP-07, FE-CONS-05).
- Close on Give must not drop typed text unless discard was confirmed
  (FE-SIMP-09).
- `AppIconButton` with `Copy.close`; 48dp (FE-A11Y-01, FE-A11Y-02).
- Do not change Save / Download / Delete primary actions.

## Definition of done

- [x] Give us feedback, Download feedback and Delete feedback each show a labelled Close; one tap leaves that surface.
- [x] Closing Give us feedback keeps the message and shots unless discard was confirmed.
- [x] The draft bar can be dismissed; cancel on the confirm leaves it open.
- [x] Tests: Give close folds with the message on the bar and no discard dialog; Download/Delete close pops; bar close + confirm clears the draft, cancel leaves the bar.
