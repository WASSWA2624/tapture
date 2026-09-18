# 007 — Add repeat external window screenshots

**Feedback:** FBK0000003, FBK0000005 · **Type:** Suggestion · **Priority:** P6 · **Effort:** M · **Depends on:** 003, 006

## Goal
On the web, the first tap on *Screenshot external window* opens the picker once and adds a still. Each later
tap adds a new still of that window without the picker. Meanwhile the operator keeps typing or dictating in
the form or in the folded bar, and moves through the app. Sharing ends on *Stop sharing*, Save, discard, or
the browser's own stop. This works at compact, medium and expanded widths, docked or full-screen, in light,
dark and outdoor.

## Evidence
- FBK0000003: the operator should be able to go to an external window or app, take any number of
  screenshots, and keep typing or using speech-to-text in the feedback field.
  `screenshots/FBK0000003-2.png` shows the external-window button in the docked panel (web, expanded, dark).
- FBK0000005: apply every change to all screen sizes and devices.
- Root cause: every tap runs `addWindow` (`give_feedback_controller.dart:87-112`), which opens the picker
  and stops the stream after one frame. That controller is `autoDispose` with the form
  (`give_feedback_controller.dart:190-194`), so the folded bar (`feedback_draft_bar.dart`) cannot take a
  still at all.

## Scope
- Change:
  - New `frontend/lib/features/feedback/presentation/feedback_window_share_controller.dart`: a
    `Notifier<bool>` (true while sharing), kept alive with a comment saying why (FE-STATE-09), exposed as
    `feedbackWindowShareProvider`.
    - `Future<String?> addStill()`: `start` if not sharing, then `still`, `FeedbackShotFit.cap`, and
      `FeedbackDraftController.addShot(label: Copy.feedbackOtherWindow)`. It returns a problem or null, with
      the same failure and cancel handling as today.
    - `stop()`.
    - It listens to `ScreenCapture.ended` and to `feedbackDraftProvider`, and stops when the draft becomes
      null (saved or discarded).
  - `give_feedback_controller.dart`: remove `addWindow`, whose job moves to the new controller.
  - `feedback_shots.dart`: the external-window button calls `addStill` and is `selected` while sharing.
    While sharing, add an `AppIconButton(icon: Icons.stop_screen_share_outlined,
    tooltip: Copy.feedbackStopSharing)` beside it, and a one-line `AppText.caption`
    `Copy.feedbackSharingWindow` under the capture row. That caption is the non-colour signal
    (FE-A11Y-05).
  - `feedback_draft_bar.dart`: while sharing, show the external-window button before *Continue feedback*.
    It takes a still and shows the same snack.
  - `copy.dart`: add `feedbackStopSharing` ('Stop sharing window') and `feedbackSharingWindow`
    ('Sharing a window. Each tap adds a screenshot.').
  - After each still, show `showAppSnack(Copy.feedbackShotAdded(Copy.feedbackOtherWindow))` so the change
    is announced (FE-A11Y-07). When full, show `Copy.feedbackShotsFull` and keep sharing.
- Do not change: `AppConstants.userFeedback.maxShots` (see Human review), *Screenshot current screen*,
  camera, library, native platforms (the control stays hidden), or the workbook.

## Rules
- FE-STATE-02, FE-STATE-04 and FE-STATE-06: the sharing flag lives in its own notifier, and the draft stays
  the single source for the images.
- FE-SEC-07: a still is taken only on a tap. The browser's own indicator stays visible while sharing.
- FE-SEC-10 and FE-CODE-08: pixels are never logged or sent anywhere.
- FE-CONS-01 and FE-CONS-08: `AppIconButton`, with one icon per concept.
- FE-A11Y-01, FE-A11Y-02 and FE-A11Y-07: 48dp, labels, tooltips and announcements.
- FE-RESP-06 and FE-A11Y-03: the bar and the shots row do not overflow at 360dp or at 200 percent text.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening add-repeat-external-window-screenshots "Add repeat external window screenshots"`
   (FE-FLOW-08).
2. Add the copy and the new controller with its provider.
3. Move `addWindow` out of `GiveFeedbackController`, and wire `feedback_shots.dart` and
   `feedback_draft_bar.dart`.
4. Add tests:
   - new `frontend/test/features/feedback/presentation/feedback_window_share_controller_test.dart`:
     - two taps add two stills from one `start`;
     - cancel adds nothing and is not sharing;
     - `ended` clears sharing;
     - Save and discard call `stop`;
     - when full, it reports `feedbackShotsFull`.
   - `give_feedback_screen_test.dart`:
     - "while sharing, the bar offers another still and typing still works";
     - "Stop sharing hides the stop control";
     - "at 360 dp and 200 percent text the bar and shots row do not overflow".
   - Update the existing external-window tests (lines 198-240) for the new controller.

## Human review
⛔ Stop before step 2 and ask:
- Task 296 required stopping every track after one frame. Should the window stay shared until *Stop
  sharing*, Save, discard or the browser's stop? Recommend yes. The browser shows its own indicator, and a
  still is taken only on a tap.
- The reporter asked for "any number" of screenshots, but drafts are capped at `maxShots` (8). Keep 8, or
  raise it (which also grows workbook size)? Recommend keeping 8 and showing `feedbackShotsFull`.
Proceed only with an explicit answer. If the answer is "proceed", keep the stream live and keep the cap
at 8.

## Acceptance criteria
- [ ] Web: one picker, then N taps add N stills of the chosen window, up to the cap, with no picker in
      between.
- [ ] Typing and dictation into the form or the bar keep working while sharing, and focus stays in Tapture
      where the browser allows it.
- [ ] The folded bar shows the external-window button only while sharing, and a tap adds a still.
- [ ] Sharing stops, and the browser indicator disappears, on *Stop sharing*, Save, discard, or the
      browser's own stop. After that the button reopens the picker.
- [ ] At compact 360dp, medium, and expanded docked, in light, dark and outdoor, at 100 and 200 percent
      text: no overflow, and every control is labelled and 48dp.
- [ ] Android, iOS and desktop show no external-window control, and nothing else changes.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Manual on Chrome: share a window, take three stills while switching to that window between taps, fold the
  form, take a fourth from the bar, then Save. The entry has four images and the sharing bar is gone.
