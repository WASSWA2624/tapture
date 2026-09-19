# 005 — Unify the confirmation dialog design

**Feedback:** FBK0000007 · **Type:** Improvement · **Priority:** P4 · **Effort:** M · **Depends on:** —

## Goal
Every confirmation uses one catalogue design at every width: capped at a readable width on tablets and
desktops, and full width less the standard inset on phones. Destructive confirmations carry an icon as
well as colour. The feedback feature defines its "discard draft" confirmation once. Because `AppDialog`
is shared, the change also applies to non-feedback confirmations, in light, dark and outdoor.

## Evidence
- FBK0000007: the reporter asks for a better look and feel for the feedback-related confirmation dialogs
  on every screen size and platform, and for the confirmation to be defined uniformly.
  `screenshots/FBK0000007.png` shows the Settings screen Feedback was tapped on, not a dialog. Android,
  mobile, compact, portrait, system dark.
- Every feedback confirmation already goes through `showAppConfirm` → `AppDialog`
  (`frontend/lib/core/widgets/feedback/app_dialog.dart:57-104`). The shared API is right; the look is
  what is wrong.
- Width: `AppDialog` sets no maximum. `Dialog` only gives a 280 dp minimum, and the body `Column`
  stretches, so at 1280 dp the confirmation spans almost the whole window, with two small buttons at the
  far end. Seen in the web preview at `c4eb48c` (Storage → Clear cache, the same widget). It also keeps
  `Dialog`'s default inset, while `AppPanelDialog` uses `Space.x6`
  (`frontend/lib/core/widgets/feedback/app_panel_dialog.dart:56`).
- Duplication: the discard-draft confirmation is written out three times, at
  `feedback_draft_bar.dart:166-176`, `feedback_overlay.dart:88-106` (desktop exit) and
  `give_feedback_screen.dart:176-187`. Its title `Copy.feedbackDiscardDraft`, "Discard draft"
  (`frontend/lib/core/copy/copy.dart:919`), is also the menu label. It is the only confirmation title
  that is not a question, and its message names no count (FE-SIMP-07).
- A destructive confirmation signals danger by colour and label only (FE-THEME-05).

## Scope
- Change:
  - `frontend/lib/app/theme/sizes.dart`: add `Sizes.dialogMaxWidth` (560, the Material 3 dialog maximum).
  - `app_dialog.dart`: cap the width with that token, use `insetPadding: EdgeInsets.all(Space.x6)`, and
    decide the destructive icon and the button layout from the review.
  - `frontend/lib/features/feedback/presentation/feedback_confirmations.dart` (new):
    `Future<bool> confirmDiscardFeedbackDraft(BuildContext context, {required int images})`. Use it at the
    three call sites above.
  - `copy.dart`: add `feedbackDiscardDraftTitle` ("Discard this feedback?"). Turn
    `feedbackDiscardDraftMessage` into an ICU plural on `images`. Keep `feedbackDiscardDraft` as the menu
    label.
  - Tests and goldens as listed in the steps.
- Do not change: the `showAppConfirm` and `showAppAlert` signatures, the delete confirmation copy, the
  browser's own leave-page prompt (task 297, drawn by the browser), `AppPanelDialog`, or undo behaviour.

## Rules
- FE-CONS-05: one dialog API, and confirmations look the same in every feature. FE-CONS-01: extend
  `AppDialog`; never add a second dialog.
- FE-THEME-01, FE-THEME-07 and FE-THEME-11: tokens only; the new width is a token.
- FE-THEME-05 and FE-A11Y-05: danger carries an icon and text as well as colour.
- FE-SIMP-07: name the consequence and the count; Cancel is the safe default.
- FE-L10N-01 and FE-L10N-03: new strings live in `Copy`, and plurals use ICU.
- FE-RESP-04, FE-A11Y-01 and FE-A11Y-03: capped width, 48 dp buttons, and no clipping at 200 percent.
- FE-CONS-02 and FE-CONS-03: update the gallery entry (`widget_gallery_screen.dart:824-837`) and the
  goldens.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening unify-confirmation-dialog-design "Unify the confirmation dialog design"`
   (FE-FLOW-08).
2. Add the token, then cap and inset `AppDialog`.
3. Apply the review's choices for the destructive icon and the button layout.
4. Add `confirmDiscardFeedbackDraft`, and replace the three hand-written calls. Pass the draft's current
   image count.
5. Update `Copy` and `frontend/test/core/copy/copy_test.dart` (zero, one and many images).
6. Tests:
   - `frontend/test/core/widgets/feedback/app_dialog_test.dart`: width is at most `Sizes.dialogMaxWidth`
     at 1280 dp; full width less the inset at 360 dp; no overflow at 200 percent text; the destructive
     icon is present, and absent when not destructive.
   - `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`: the bar's Close, the
     form's Discard draft and the desktop exit show the same title and the counted message.
   - Regenerate the dialog goldens in light, dark and outdoor.

## Human review
⛔ Stop before step 3 and ask:
- Destructive icon: show `Icons.warning_amber_outlined` in `danger` beside the title? Recommend yes.
- Buttons on a phone: (a) keep the end-aligned row, which wraps when it must, or (b) stack full-width
  buttons with Cancel below? Recommend (a), because it matches Material and every other width.
- Title: use "Discard this feedback?" with a counted message? Recommend yes.
Proceed only with an explicit answer. If the answer is "proceed", take every recommendation.

## Acceptance criteria
- [ ] At 1280 dp, every confirmation is at most 560 dp wide and centred. At 360 dp it fills the width
      less 24 dp each side.
- [ ] Delete feedback, Discard draft (from the bar, the form and a desktop exit), Clear cache and Discard
      changes all share one layout.
- [ ] A destructive confirmation shows an icon, a title question and a named action.
- [ ] Discarding a draft with 3 images reads "…its 3 images…"; with none, it names no images.
- [ ] No clipping at 200 percent text or in landscape, in light, dark and outdoor.
- [ ] FBK0000007 is resolved.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- Regenerate with `--update-goldens` only `test/design_system/app_dialog/` and the `app_dialog_*` images
  in `test/design_system/goldens/`, and list every file regenerated.
