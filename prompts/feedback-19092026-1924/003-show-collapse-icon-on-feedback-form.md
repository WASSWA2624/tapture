# 003 — Show a collapse icon on the feedback form

**Feedback:** FBK0000016 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **Depends on:** —

## Goal
The control that folds Give us feedback into its bar looks and reads as "collapse", not "close". The
bar's control that discards the draft says so. An X then means one thing across the feedback surfaces.
This applies at compact, medium and expanded widths, in light, dark and outdoor, and at 200 percent text.

## Evidence
- FBK0000016 (first part): the form's collapse button is easily taken for a close button and should look
  like collapse. `screenshots/FBK0000016.png` shows the project home Feedback was tapped on;
  `screenshots/FBK0000014-2.png` shows the form with an X at its top start. Android, mobile, compact,
  portrait, system dark.
- Root cause: the form's leading control is `Icons.close`, labelled `Copy.close`, yet it calls
  `_draft.collapse` and keeps everything
  (`frontend/lib/features/feedback/presentation/give_feedback_screen.dart:100-106`).
- In the folded bar, the same `Icons.close` with the label `Copy.close` discards the draft after a
  confirmation (`feedback_draft_bar.dart:151-157`). The bar's expand control is `Icons.open_in_full`
  (`:144-150`). One icon has two meanings (FE-CONS-08).
- `Copy.feedbackShotTipScreens` tells people to "tap Close" to reach another screen
  (`frontend/lib/core/copy/copy.dart:1159-1161`). `Copy.feedbackContinueLater` ("Continue later",
  `:1201`) exists for exactly this action.

## Scope
- Change:
  - `give_feedback_screen.dart`: the leading `AppIconButton` uses `Icons.close_fullscreen`, the mirror
    of the bar's `open_in_full`, with `Copy.feedbackContinueLater` as its label and tooltip.
  - `feedback_draft_bar.dart`: the discard control keeps `Icons.close` but takes
    `Copy.feedbackDiscardDraft` as its label and tooltip.
  - `copy.dart`: rewrite `feedbackShotTipScreens` to name "Continue later" instead of "Close".
  - Tests, listed in the steps.
- Do not change: fold, expand or discard behaviour; the discard confirmation (task 308); the Close
  controls of Download feedback and Delete feedback, which really close; or the floating menu.

## Rules
- FE-CONS-08: one icon per concept. Collapse and expand are a pair, and X means close or discard.
- FE-A11Y-02: the semantic label says what the control does.
- FE-SIMP-10: plain language. FE-L10N-01: `Copy` only.
- FE-A11Y-01: 48 dp, unchanged.
- FE-THEME-08: icons from the one Material family at token size.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening show-collapse-icon-on-feedback-form "Show a collapse icon on the feedback form"`
   (FE-FLOW-08).
2. Swap the form's icon and label, relabel the bar's discard control, and update the tip.
3. Tests in `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`:
   - the form's leading control has the label "Continue later", uses `Icons.close_fullscreen`, and folds
     the draft with its text kept;
   - the bar's X has the label "Discard draft" and still asks before discarding;
   - update the finders that looked for `Copy.close` on these two controls, and leave Download and Delete
     as they are;
   - `frontend/test/core/copy/copy_test.dart` for the new tip.

## Human review
⛔ Stop before step 2 and ask:
- Task 293 made "Close" the obvious way off every feedback surface. This report says Close misleads on
  the form. Replace the form's X with a collapse icon labelled "Continue later"? Recommend yes; the fold
  keeps the draft, so "Close" misstates it.
- Relabel the bar's X from "Close" to "Discard draft"? Recommend yes; that is what it does.
Proceed only with an explicit answer. If the answer is "proceed", take both recommendations.

## Acceptance criteria
- [ ] The form's top-start control shows a collapse icon, and a screen reader hears "Continue later".
- [ ] Tapping it folds the form into the bar with the text and images kept.
- [ ] The bar's X is announced as "Discard draft" and still confirms before clearing.
- [ ] The tip on the form names "Continue later".
- [ ] It looks right in light, dark and outdoor, at 360 dp and 200 percent text.
- [ ] FBK0000016's first part is resolved. The navigation icons and Capture styling are 004.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- No goldens change.
