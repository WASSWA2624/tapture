# 006 — Add a window share session to screen capture

**Feedback:** FBK0000003 · **Type:** Suggestion · **Priority:** P6 · **Effort:** M · **Depends on:** none

## Goal
`ScreenCapture` can hold one shared window open and take any number of stills from it without reopening
the browser picker. It can also report when the operator stops sharing from the browser's own control. What
users see does not change yet: Give us feedback still takes one still and stops at once. 007 builds the
multi-still flow on top of this.

## Evidence
- FBK0000003: *Screenshot external window* should let the operator go to another window or app and take
  any number of screenshots, while still typing or dictating into the feedback field.
- Root cause: `ScreenCapture.capture` (`frontend/lib/core/files/screen_capture.dart:30-33`) is one-shot. The
  web version opens `getDisplayMedia`, grabs one frame and stops every track in `finally`
  (`screen_capture_web.dart:28-48`). Every still reopens the picker, and the picker hands focus to the
  shared surface, which takes the operator away from the text field.

## Scope
- Change:
  - `screen_capture.dart`: replace `capture` with a session. Give each member a one-line doc:
    - `Future<Result<bool>> start()`: picks and starts sharing. `Success(false)` means the operator
      cancelled.
    - `bool get isSharing`.
    - `Stream<void> get ended`: fires when sharing stops for any reason, including the browser's
      *Stop sharing*.
    - `Future<Result<Uint8List>> still({required int longEdge})`: one PNG of the shared surface now.
    - `void stop()`: stops every track, and does nothing if nothing is shared.
  - Keep `canCapture`, `screenCaptureFailure` and `screenCaptureCancelled`. `ScreenCapture.fake` gains
    `frames` (a list handed out in turn), `failure`, `canCapture`, and a public `stops` count for tests.
  - `screen_capture_web.dart`: keep the `MediaStream` and one hidden `<video>` from `start` until `stop`,
    reusing `_snapshot`'s canvas code for each still. Listen for the video track's `ended` event. Where
    `window.CaptureController` exists, pass one with `setFocusBehavior('no-focus-change')` so Tapture keeps
    focus. Never request audio.
  - `screen_capture_io.dart` and `screen_capture_stub.dart`: `canCapture` stays false, `start` returns
    `Success(false)`, and the other members do nothing.
  - `frontend/lib/features/feedback/presentation/give_feedback_controller.dart:87-112`: `addWindow` now
    calls `start`, then `still`, then always `stop`. The user-facing result is the same as today.
- Do not change: the controls in `feedback_shots.dart`, `maxShots`, copy, camera, library, *Screenshot
  current screen*, or the workbook.

## Rules
- FE-STR-11: display APIs only in this core service, with a fake. FE-FLOW-06: `dart:js_interop`, no new
  package.
- FE-SEC-07 and FE-SEC-10: stills only on an explicit call. Pixels are never logged or sent anywhere.
  FE-CODE-08: log no frame data.
- FE-CODE-06: public methods return `Result`, and no raw exception crosses the boundary.
- FE-CODE-07: every awaited browser promise has a cancellation path (the existing `cameraReady` timeout).
- FE-STATE-09: `stop` removes the video element and the `ended` listener.
- FE-TEST-03 and FE-TEST-10: fake-driven tests, including refusal, cancel and a mid-session end.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening add-window-share-session-api "Add a window share session to screen capture"`
   (FE-FLOW-08).
2. Change the interface and the fake. Then change the stub and io versions.
3. Rework `screen_capture_web.dart` around a held stream, a held video and the `ended` event.
4. Switch `GiveFeedbackController.addWindow` to `start`, `still` and `stop`.
5. Tests in `frontend/test/core/files/screen_capture_test.dart`:
   - the fake hands out successive frames from one session;
   - cancel returns `false` and is not sharing;
   - a refusal maps onto catalogue copy;
   - `stop` ends the session and fires `ended`;
   - native is hidden and `start` returns false.

   Keep the existing tests in `give_feedback_screen_test.dart` (lines 198-240) green without editing them.

## Human review
⛔ Stop before step 2 and ask:
- This replaces the public `core/` method `ScreenCapture.capture` with a session API. Its only caller is
  `GiveFeedbackController.addWindow`. Replace it, or add the session beside `capture`? Recommend replacing
  it, so there is one way to capture (FE-CONS-01).
Proceed only with an explicit answer. If the answer is "proceed", replace it.

## Acceptance criteria
- [ ] Web: one `start` followed by three `still` calls gives three PNGs, each capped to `longEdge`, from one
      picker.
- [ ] Web: after `stop`, or after the browser's *Stop sharing*, `isSharing` is false, `ended` has fired
      and the sharing indicator is gone.
- [ ] Chromium: after picking a window, keyboard focus stays in Tapture.
- [ ] Give us feedback behaves exactly as before: one still per tap, and no stream left running after a
      still, a cancel or a refusal.
- [ ] Android, iOS and desktop: the control stays hidden, and everything else works at compact, medium and
      expanded widths.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Manual web check (Chrome): *Screenshot external window* still adds one still, and the browser's sharing
  bar disappears straight after.
- No goldens change.
