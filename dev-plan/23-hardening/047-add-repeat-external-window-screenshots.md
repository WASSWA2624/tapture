# 047 — Add repeat external window screenshots

**Phase** 23 · Hardening  |  **Depends on** [046](046-add-window-share-session-api.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On the web, one display picker starts a share; later taps add stills of
that window until Stop sharing, Save, discard, or the browser stops it.
The folded bar can take another still. The draft still caps at eight
images.

## Files

- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/feedback/presentation/feedback_window_share_controller.dart`
- `frontend/lib/features/feedback/presentation/give_feedback_controller.dart`
- `frontend/lib/features/feedback/presentation/feedback_shots.dart`
- `frontend/lib/features/feedback/presentation/feedback_draft_bar.dart`
- `frontend/test/core/copy/copy_test.dart`
- `frontend/test/features/feedback/presentation/feedback_window_share_controller_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

## Constraints

- Sharing lives in its own notifier; images stay on the draft (FE-STATE-02,
  FE-STATE-04, FE-STATE-06). Kept alive for the bar (FE-STATE-09).
- A still is taken only on a tap (FE-SEC-07). Pixels are never logged
  (FE-SEC-10, FE-CODE-08).
- Reuse `AppIconButton` (FE-CONS-01, FE-CONS-08). 48dp, labelled, snacks
  (FE-A11Y-01, FE-A11Y-02, FE-A11Y-07). Caption is the non-colour signal
  (FE-A11Y-05).
- No overflow at 360 dp or 200 percent text (FE-RESP-06, FE-A11Y-03).
- Do not change `maxShots`, current-screen capture, camera, library,
  native platforms, or the workbook.

## Definition of done

- [x] One picker, then N taps add N stills, up to eight, with no picker
      in between.
- [x] The bar offers another still while sharing; typing still works.
- [x] Sharing ends on Stop sharing, Save, discard, or the browser's stop.
- [x] When full, `feedbackShotsFull` is shown and sharing stays live.
- [x] Tests: two stills from one start; cancel; ended; Save/discard stop;
      full; bar still; stop hides; no overflow at 360 dp / 200 percent.
