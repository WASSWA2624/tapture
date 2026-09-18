# 001 — Warn before closing the tab with a draft

**Feedback:** FBK0000003 · **Type:** Gap · **Priority:** P1 · **Effort:** M · **Depends on:** none

## Goal
On the web, closing or reloading the browser tab while a feedback draft holds work shows the browser's own
"Leave site?" prompt. Cancelling it keeps the draft. This applies on every width (compact, medium, expanded)
and in light, dark and outdoor themes, whether the form is open, docked or folded into the bar.

## Evidence
- FBK0000003 (last sentence): closing the feedback screens with unsaved work should give appropriate
  warnings. Reported on web, desktop, expanded, dark theme.
- Already covered, so do not redo:
  - The bar's Close confirms before discarding (`feedback_draft_bar.dart:137-148`).
  - *Discard draft* in the form's menu confirms (`give_feedback_screen.dart:176-187`).
  - The form's Close folds the form into the bar and keeps everything
    (`give_feedback_screen.dart:100-106`, `feedback_draft_controller.dart:46-48`; task 293).
- Root cause: the draft lives only in memory (`feedbackDraftProvider`,
  `feedback_draft_controller.dart:117-121`), and nothing in `lib/` listens for `beforeunload`. A search for
  `beforeunload`, `onExitRequested` and `didRequestAppExit` finds nothing. Closing the tab drops the draft
  without a word.

## Scope
- Change:
  - `frontend/lib/features/feedback/presentation/feedback_draft.dart`: add a `hasWork` getter that is true
    when `open` is true and the message is not blank, the Other name is not blank, or `shots` is not empty.
    It deliberately matches the bar's Close, which always confirms.
  - New `frontend/lib/core/lifecycle/leave_guard.dart`, plus `leave_guard_web.dart` and
    `leave_guard_stub.dart` behind the same conditional import `screen_capture.dart:7-10` uses. `LeaveGuard`
    has `hold(Object owner)`, `release(Object owner)`, `bool get isHeld` and a `LeaveGuard.fake()`. The web
    version adds one `beforeunload` listener while any owner holds and removes it when the last one
    releases. Export it from `frontend/lib/core/lifecycle/lifecycle.dart`.
  - `leaveGuardProvider` in `core/lifecycle/`, defaulting to the fake like `lifecycleObserverProvider`;
    `frontend/lib/main.dart` overrides it with `LeaveGuard()`.
  - `frontend/lib/features/feedback/presentation/feedback_overlay.dart`: in `_FeedbackOverlayState`, call
    `ref.listenManual` on `feedbackDraftProvider.select((d) => d?.hasWork ?? false)` with
    `fireImmediately: true`, then hold or release the guard. Release it in `dispose`.
- Do not change: fold-on-Close, the bar and discard confirms, Save, Download feedback, Delete feedback, and
  native Android, iOS or desktop behaviour (desktop is 002). Drafts are not persisted here (see Open
  questions in `INDEX.md`).

## Rules
- FE-STR-11: browser access only through the new `core/` service with a fake. The feature never touches
  `window`.
- FE-FLOW-06: no new package. Use `dart:js_interop` as `screen_capture_web.dart` does.
- FE-STATE-06: `hasWork` is derived from the draft and never stored.
- FE-STATE-09: release on dispose. FE-STR-04: `core/` never imports `features/`.
- FE-SIMP-07 and FE-SIMP-09: exactly one prompt, and it is the browser's own. No second dialog.
- FE-CODE-12: one-line docs on the new public API. FE-TEST-01 and FE-TEST-03: fakes, not mocks.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening warn-before-closing-tab-with-draft "Warn before closing the tab with a draft"`
   (FE-FLOW-08).
2. Add `FeedbackDraft.hasWork` with its doc comment.
3. Add `LeaveGuard` (interface, fake, stub and web), the provider and the barrel export. The stub's
   `hold` and `release` only record owners.
4. Override the provider in `main.dart`, then wire the listener in `feedback_overlay.dart`.
5. Add tests:
   - `frontend/test/core/lifecycle/leave_guard_test.dart`: the fake holds while any owner holds, and
     releasing one of two owners keeps it held.
   - `frontend/test/features/feedback/presentation/feedback_draft_controller_test.dart`: `hasWork` is false
     for a closed draft and for an open one with nothing in it, and true for text, an Other name or a shot.
   - `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`: typing arms the fake
     guard, and a successful Save or a confirmed discard releases it.

## Human review
⛔ Stop before step 4 and ask:
- Should Close on the full form keep folding in one tap with no dialog (task 293), or ask Keep / Discard
  whenever the draft has work? Recommend keeping the one-tap fold, because nothing is lost and FE-SIMP-07
  discourages extra dialogs.
Proceed only with an explicit answer. If the answer is "proceed", keep the one-tap fold and build only the
tab guard.

## Acceptance criteria
- [ ] Web, compact, medium and expanded: with typed text, closing or reloading the tab shows the browser's
      leave prompt, and Cancel keeps the text and images.
- [ ] Web: the prompt also shows while the draft is folded into the bar or docked beside the app.
- [ ] Web: after a successful Save, or once discard is confirmed, closing the tab shows no prompt.
- [ ] No prompt when no draft has been started, including after only opening the Feedback menu.
- [ ] Native builds compile and behave as before (the stub).
- [ ] FBK0000003's warning part is closed for the web. Desktop window close is covered by 002.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Manual on web (Chrome and one other browser): type a draft, press Ctrl+R, and see the prompt. Save, press
  Ctrl+R, and see no prompt.
- No goldens change.
