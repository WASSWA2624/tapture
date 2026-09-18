# 003 — Align the feedback shot controls

**Feedback:** FBK0000003, FBK0000005 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **Depends on:** none

## Goal
In Give us feedback, *Include the feedback UI* becomes a checkbox styled like *Attach N images*. The capture
buttons get the reporter's names, *Screenshot current screen* and *Screenshot external window*, and move to
their own row. That way no label is squeezed into several lines on a compact phone, and the section reads
the same at compact, medium and expanded widths (including the docked panel), in all three themes and at
200 percent text.

## Evidence
- FBK0000003: make *Include the feedback UI* a checkbox like *Attach x images*. Rename the *Add this screen*
  tooltip to "Screenshot current screen" and *Add another window* to "Screenshot external window".
  `screenshots/FBK0000003-2.png` shows the docked panel (expanded, dark) with one row: the Attach checkbox,
  a selected include-UI icon toggle, and four capture icons.
- FBK0000005: every change should apply to all screen sizes and devices.
  `screenshots/FBK0000005-2.png` shows the full-screen form at compact width, where the icon row squeezes
  "Attach 1 image" into three lines. `FBK0000005.png` repeats the Settings screen only.
- Root cause: `feedback_shots.dart:57-121` puts `Expanded(AppSwitchTile.checkbox)` and up to five 48dp
  `AppIconButton`s in one `Row`, which leaves the label about 90dp at 360dp. The include-UI control is an
  icon toggle (`feedback_shots.dart:77-88`).

## Scope
- Change:
  - `frontend/lib/features/feedback/presentation/feedback_shots.dart`, in this order:
    1. `AppSwitchTile.checkbox(title: Copy.feedbackAttachImages(n))`, or the `Copy.feedbackNoScreenshot`
       caption when there are no images.
    2. When `onAddScreen != null`, `AppSwitchTile.checkbox(title: Copy.feedbackIncludeUi,
       value: includeUi, dense: true, controlFirst: true, divided: false)`, which calls
       `FeedbackDraftController.setIncludeUi`.
    3. The capture `AppIconButton`s in their own start-aligned row: current screen, external window
       (`canCapture`), camera (`canTakePhoto`), then choose photos.
    4. The gallery, unchanged.
  - `frontend/lib/core/copy/copy.dart`: `feedbackAddScreen` becomes 'Screenshot current screen',
    `feedbackAddWindow` becomes 'Screenshot external window', and `feedbackOtherWindow` (the still's label)
    becomes 'External window' so the vocabulary is the same (FE-CONS-07). Update the three doc comments.
    Keep the keys.
- Do not change: what each button captures, the include-UI default (off), `maxShots`, the gallery, the
  Feedback menu layout, the workbook, or `AppSwitchTile` and `AppIconButton` themselves.

## Rules
- FE-CONS-01: reuse `AppSwitchTile.checkbox` and `AppIconButton`. No new widget.
- FE-L10N-01 and FE-L10N-02: strings live in `Copy`, and keys name meaning.
- FE-L10N-05: start and end alignment only.
- FE-RESP-02: no width checks. Stacking the rows works at every width.
- FE-RESP-06, FE-RESP-10 and FE-A11Y-03: no clipping at 200 percent text.
- FE-A11Y-01 and FE-A11Y-02: 48dp targets, each with a label and a tooltip.
- FE-THEME-01: tokens only for spacing (`Space.*`).

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening align-feedback-shot-controls "Align the feedback shot controls"`
   (FE-FLOW-08).
2. Change the three `Copy` values and their doc comments.
3. Rebuild the `FeedbackShots` layout as listed in Scope, and delete the `Icons.web_asset_outlined` toggle.
4. Update `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`:
   - The include-UI tests (around lines 367-416) now find the checkbox by its text and assert it is
     checked.
   - Add "at 360 dp each checkbox label sits on one line": with images attached, the label's height equals
     one line of `AppText.label`.
   - Add "at 360 dp and 200 percent text the shots section does not overflow".
   - Add "on a wide window the docked panel shows both checkboxes and the capture row".
5. Update `frontend/test/core/copy/copy_test.dart` if it pins values.

## Human review
⛔ Stop before step 2 and ask:
- The Feedback menu also uses `Copy.feedbackAddScreen` (`feedback_overlay.dart:161`). Should the menu item
  read "Screenshot current screen" too? Recommend yes, for one vocabulary (FE-CONS-07).
- Order: Attach, then Include UI, then the capture buttons. Or should the capture buttons come first?
  Recommend the order in Scope, so the two checkboxes sit together.
Proceed only with an explicit answer. If the answer is "proceed", rename the menu item too and use the
order in Scope.

## Acceptance criteria
- [ ] *Include the feedback UI* is a checkbox with the same look, size and spacing as *Attach N images*,
      and it is off by default.
- [ ] Ticking it makes *Screenshot current screen* capture the feedback UI too, as it does today.
- [ ] The tooltips and semantic labels read "Screenshot current screen" and "Screenshot external window".
- [ ] At 360dp and 100 percent text, neither checkbox label wraps (FBK0000005).
- [ ] At 360dp and 200 percent text, nothing overflows or clips. The section scrolls with the form.
- [ ] Medium full-screen and the expanded docked panel show the same order, in light, dark and outdoor.
- [ ] Native builds without a display picker show no external-window button, and nothing else moves.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- No design-system goldens change. If one does, stop and find out why.
