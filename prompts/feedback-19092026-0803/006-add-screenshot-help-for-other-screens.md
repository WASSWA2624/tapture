# 006 — Add screenshot help for other screens

**Feedback:** FBK0000004 · **Type:** Improvement · **Priority:** P5 · **Effort:** S · **Depends on:** —

## Goal
On a phone or tablet, the operator can see how to add a screenshot of another Tapture screen or another
app. The folded feedback bar offers "Screenshot current screen" in one tap, and the form explains both
routes in plain words on platforms that cannot capture other windows. This works at compact, medium and
expanded widths, in light, dark and outdoor, and at 200 percent text.

## Evidence
- FBK0000004: on mobile, it is hard to work out how to switch to other screens, or to other apps, and
  screenshot them for feedback. No image. Android, mobile, compact, portrait, system dark.
- On a phone the form fills the screen (`frontend/lib/features/feedback/presentation/feedback_overlay.dart:143-146`).
  To capture another screen, the operator must tap Close, which only folds the form
  (`give_feedback_screen.dart:100-106`), move to the screen, open the floating Feedback menu, and choose
  "Screenshot current screen" (`feedback_overlay.dart:211-217`). Nothing on screen says so.
- The folded bar (`feedback_draft_bar.dart:118-140`) offers expand and close, plus a window still only
  while a web share runs.
- Other apps: "Screenshot external window" is web-only. `frontend/lib/core/files/screen_capture.dart:15`
  says native platforms hide it, and `screen_capture_io.dart:16` returns `false`. On a phone, the only
  way is a system screenshot added with "Choose photos" (`feedback_shots.dart:121-127`), which the form
  never mentions.
- `Copy.feedbackContinueLater` and `Copy.feedbackDraftBarHint` (`frontend/lib/core/copy/copy.dart:926-930`)
  are defined but unused.

## Scope
- Change:
  - `feedback_draft_bar.dart`: take an optional `onAddScreen`. When it is set, show an `AppIconButton`
    with `Icons.screenshot_monitor_outlined`, labelled `Copy.feedbackAddScreen`, before the expand
    control.
  - `feedback_overlay.dart`: pass `() => unawaited(_addThisScreen())` to the bar.
  - `feedback_shots.dart`: when `canCapture` is false, show two `AppText.caption` lines under the shot
    controls: `Copy.feedbackShotTipScreens` and `Copy.feedbackShotTipApps`.
  - `copy.dart`: add those two keys. Defaults: "Another screen: tap Close, open it, then tap Screenshot
    current screen in the bar." and "Another app: take a screenshot with your device, then add it with
    Choose photos."
  - Tests, listed in the steps.
- Do not change: the Close control's label or behaviour (task 293), the floating menu, web window
  sharing, the image cap, or `Copy.feedbackContinueLater` and `Copy.feedbackDraftBarHint`.

## Rules
- FE-CONS-01 and FE-CONS-08: reuse `AppIconButton` and the menu's icon for the same action.
- FE-SIMP-10 and FE-SIMP-11: plain language that names the next action.
- FE-L10N-01 and FE-L10N-06: strings in `Copy`, with room for 35 percent longer text.
- FE-A11Y-01, FE-A11Y-02 and FE-A11Y-07: 48 dp and labelled, and the result is announced by the existing
  snack.
- FE-SEC-07: a still is taken only when the operator taps.
- FE-STATE-04: the bar calls a callback and keeps no capture logic.
- FE-RESP-06: no overflow at 360 dp.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening add-screenshot-help-for-other-screens "Add screenshot help for other screens"`
   (FE-FLOW-08).
2. Add the bar control and wire it from the overlay.
3. Add the tips and the copy, and update `frontend/test/core/copy/copy_test.dart`.
4. Tests in `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`:
   - the folded bar's "Screenshot current screen" adds one image and shows `Copy.feedbackShotAdded`;
   - with `ScreenCapture.fake(canCapture: false)`, both tips show; with `canCapture: true`, neither does;
   - the bar has no overflow at 360 dp with an image count shown, at 100 and 200 percent text;
   - the new control meets the 48 dp and label matchers.

## Human review
⛔ Stop before step 2 and ask:
- Add "Screenshot current screen" to the folded bar? At 360 dp it narrows the text field by 48 dp.
  Recommend yes, because it is the one-tap answer to the report.
- Keep the two tip lines as drafted above? Recommend yes.
- Capturing other apps from inside the app on Android needs MediaProjection: a plugin (FE-FLOW-06), a
  permission and a foreground service. Recommend no; the tip covers it. If it is wanted, it becomes its
  own task.
Proceed only with an explicit answer. If the answer is "proceed", take every recommendation.

## Acceptance criteria
- [ ] With the draft folded on any screen, one tap on the bar adds a screenshot of that screen and
      confirms it.
- [ ] On Android, iOS and native desktop, the form shows both tips under the shot controls. The web,
      which can capture another window, shows neither.
- [ ] Neither the bar nor the form clips at 360 dp, at 200 percent text or in landscape, in light, dark
      or outdoor.
- [ ] FBK0000004 is resolved.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- On an Android phone: open Give us feedback, read the tips, tap Close, open Records, and tap the bar's
  screenshot control.
- No goldens change.
