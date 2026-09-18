# 295 — Include feedback UI screenshot

**Phase** 23 · Hardening  |  **Depends on** [287](287-dock-feedback-panel-beside-app.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Give us feedback can attach a screenshot of the visible workspace (docked
panel or full-screen form). Default Add this screen is still the app
without the feedback UI.

## Files

- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/feedback/presentation/feedback_draft.dart`
- `frontend/lib/features/feedback/presentation/feedback_draft_controller.dart`
- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/lib/features/feedback/presentation/feedback_shots.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/features/feedback/presentation/feedback_draft_controller_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

## Constraints

- One Add this screen action; including the UI is opt-in, default off
  (FE-SIMP-01, FE-SIMP-05).
- Reuse `AppIconButton` for the opt-in; no new shot widget (FE-CONS-01).
- Capture the overlay as laid out: trailing panel on expanded, full form
  on compact and medium (FE-L10N-05, FE-RESP-10).
- Cap to `AppConstants.userFeedback.screenshotLongEdge` (FE-PERF-04,
  FE-CODE-09).
- Do not include the floating button; it is already hidden while expanded.
- Do not change camera, library, the first menu capture, or the workbook
  screenshot sheet.

## Definition of done

- [x] Default Add this screen is the app without the feedback form, on
      compact and expanded.
- [x] With the opt-in on, the new shot is the Give us feedback UI (docked
      panel on expanded, full form on compact).
- [x] The control is labelled and 48dp; 200 percent text does not clip
      the shots row.
- [x] Tests: default capture is app-only; opt-in capture differs and is
      wider on expanded.
