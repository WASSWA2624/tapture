# 002 — Confirm desktop exit with a draft

**Feedback:** FBK0000003, FBK0000005 · **Type:** Gap · **Priority:** P1 · **Effort:** S · **Depends on:** 001

## Goal
On Windows, macOS and Linux, closing the app window while a feedback draft holds work asks before the draft
is lost. It uses the same *Discard draft* confirmation as the bar, and Cancel keeps the app open with the
draft intact. This applies on every window width and in light, dark and outdoor themes.

## Evidence
- FBK0000003: closing with unsaved work should give appropriate warnings.
- FBK0000005: every change should apply to all screen sizes and devices. 001 covers only the browser tab.
- Root cause: `LifecycleObserver` (`frontend/lib/core/lifecycle/lifecycle_observer.dart:11`) is the app's
  only `WidgetsBindingObserver`, and it does not override `didRequestAppExit`, so a window close exits at
  once. The draft lives only in memory (`feedback_draft_controller.dart:117-121`).

## Scope
- Change:
  - `frontend/lib/core/lifecycle/lifecycle_observer.dart`: add `addExitCheck(Future<bool> Function() check)`
    and `removeExitCheck(...)`, and override `didRequestAppExit`. It returns `AppExitResponse.cancel` if any
    check returns false, and `AppExitResponse.exit` otherwise. The checks run in the order they were added,
    and it stops at the first false.
  - `frontend/lib/features/feedback/presentation/feedback_overlay.dart`: register one check in `initState`
    and remove it in `dispose`. When `FeedbackDraft.hasWork` (from 001) is true, the check shows
    `showAppConfirm` with `Copy.feedbackDiscardDraft`, `Copy.feedbackDiscardDraftMessage`, `Copy.discard`
    and `destructive: true`. On confirm, clear the draft and return true.
- Do not change: web (001), Android and iOS (they cannot be warned on swipe-away; see Open questions in
  `INDEX.md`), the fold-on-Close behaviour, or any runner under `frontend/windows`, `macos` or `linux`
  without the review below.

## Rules
- FE-STR-11: exit handling stays in the single core observer. Do not add an `AppLifecycleListener` or a
  second observer.
- FE-CONS-05 and FE-SIMP-07: reuse `showAppConfirm` and the existing discard copy. No new strings.
- FE-SIMP-09: Cancel never loses the draft.
- FE-CODE-07: the check is awaited, not floated. FE-STATE-09: remove the check on dispose.
- FE-TEST-03: drive `LifecycleObserver.fake()` directly and never the platform.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening confirm-desktop-exit-with-draft "Confirm desktop exit with a draft"`
   (FE-FLOW-08).
2. Add the exit checks and `didRequestAppExit` to `LifecycleObserver`, with one-line docs (FE-CODE-12).
3. Register the draft check in `feedback_overlay.dart`, reading `lifecycleObserverProvider`.
4. Add tests:
   - `frontend/test/core/lifecycle/lifecycle_observer_test.dart`: exit with no checks, cancel when a check
     returns false, and a removed check no longer runs.
   - `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`: an exit request with a
     draft shows the discard confirm. Cancel returns `cancel` and keeps the text. Confirm returns `exit`.
     With no draft, it returns `exit` and shows no dialog.
5. Try it by hand on Windows, which is the dev machine, and on macOS and Linux if you can reach them.

## Human review
⛔ Stop before editing any runner and ask:
- If a desktop runner does not forward the window close to Flutter's exit request, should we (a) change
  that runner, (b) leave that platform unguarded and record a follow-up task, or (c) drop desktop from this
  prompt? Recommend (b), because native runner changes deserve their own review.
Proceed only with an explicit answer. If the answer is "proceed", do (b).

## Acceptance criteria
- [ ] Windows: closing the window with typed feedback shows *Discard draft*. Cancel keeps the app open and
      the text, whether the form is full-screen, docked or folded into the bar.
- [ ] Confirming closes the app.
- [ ] Closing with no draft, or after Save, exits without a dialog.
- [ ] macOS and Linux behave the same, or each gap has a follow-up task (see Human review).
- [ ] The dialog fits at 200 percent text, in light, dark and outdoor (FE-A11Y-03).
- [ ] FBK0000003's warning part is closed for desktop. FBK0000005 is honoured for this change.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- `flutter run -d windows`: type a draft and close the window, and the dialog appears.
- No goldens change.
