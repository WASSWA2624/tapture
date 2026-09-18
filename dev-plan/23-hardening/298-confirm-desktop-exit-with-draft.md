# 298 — Confirm desktop exit with a draft

**Phase** 23 · Hardening  |  **Depends on** [297](297-warn-before-closing-tab-with-draft.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On desktop, closing the window while a feedback draft holds work shows the
same Discard draft confirmation as the bar. Cancel keeps the app open and
the draft. Form Close still folds in one tap. Runners are unchanged: the
engine already forwards window close to `didRequestAppExit`.

## Files

- `frontend/lib/core/lifecycle/lifecycle_observer.dart`
- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/test/core/lifecycle/lifecycle_observer_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

## Constraints

- Exit handling stays on the one core observer (FE-STR-11).
- Reuse `showAppConfirm` and the existing discard copy (FE-CONS-05,
  FE-SIMP-07). Cancel never loses the draft (FE-SIMP-09).
- The check is awaited (FE-CODE-07) and removed on dispose (FE-STATE-09).
- Drive `LifecycleObserver.fake()` directly (FE-TEST-03).
- Do not change web, Android, iOS, fold-on-Close, or desktop runners.

## Definition of done

- [x] A window-close request with typed feedback shows Discard draft;
      Cancel keeps the text, Confirm returns exit and clears the draft.
- [x] No draft, or `hasWork` false, returns exit with no dialog.
- [x] The check still runs while the draft is folded into the bar.
- [x] Tests: no checks exit; a false check cancels; a removed check no
      longer runs; overlay cancel/confirm/no-draft as above.
