# 009 — Show a single feedback image as a thumbnail

**Feedback:** FBK0000014 · **Type:** Improvement · **Priority:** P5 · **Effort:** S · **Depends on:** —

## Goal
In Give us feedback, one attached image appears as a square thumbnail, the same kind of tile several
images use, instead of filling the form's width. A captured screen is never mistaken for live app UI, and
a tap still opens the full preview. This holds at compact, medium and expanded widths, docked or full
screen, in light, dark and outdoor, and at 200 percent text.

## Evidence
- FBK0000014 (second part): the reporter asks not to enlarge the screenshot when there is only one,
  because it looks like part of the active UI. `screenshots/FBK0000014-2.png` shows the feedback form with
  a full-width capture of the project home, including its own status bar and overflow button, directly
  under the shot controls. Android, mobile, compact, portrait, system dark.
- Root cause: `_ShotGallery` gives a single shot the whole width at its natural aspect ratio
  (`frontend/lib/features/feedback/presentation/feedback_shots.dart:202-208`), as the class comment says
  (`:22-25`). Several shots get balanced square tiles (`:209-235`).

## Scope
- Change:
  - `feedback_shots.dart`: drop the single-shot branch. One shot renders as one square `_ShotTile`
    (`square: true`), sized `min(AppConstants.userFeedback.galleryTile, width)` and aligned to the start.
    Two or more keep today's balanced rows. Update the class comment.
  - `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`: the tests below.
- Do not change: the preview dialog (`_preview`, which still shows the full image), the remove control,
  the image cap, the attach and include-UI checkboxes, or how several images lay out.

## Rules
- FE-CONS-06 and FE-PERF-04: thumbnails in the form, and full images only in the viewer. Decode at the
  drawn size (`cacheWidth`), as the tile already does.
- FE-RESP-09: ratios and `BoxFit.cover`, not pixel sizes. FE-RESP-04: nothing stretches edge to edge.
- FE-L10N-05: start alignment mirrors in right-to-left.
- FE-A11Y-01 and FE-A11Y-02: the tile and its remove control keep 48 dp targets and labels.
- FE-THEME-01: tokens only; `galleryTile` already exists in `AppConstants`.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening show-single-feedback-image-as-thumbnail "Show a single feedback image as a thumbnail"`
   (FE-FLOW-08).
2. Replace the single-shot branch, and update the comment.
3. Tests:
   - with one image, at 393 dp and at the 420 dp docked panel width, the tile is square and no wider than
     `galleryTile`;
   - tapping it opens the preview at full width;
   - with three images, the layout is unchanged;
   - no overflow at 200 percent text.

## Acceptance criteria
- [ ] One attached image shows as a thumbnail of about 160 dp, not a full-width picture.
- [ ] Tapping the thumbnail opens the large preview, and its X removes it.
- [ ] Two or more images look as they do today.
- [ ] It looks right in light, dark and outdoor, docked and full screen, and at every width.
- [ ] FBK0000014's second part is resolved. The home count cards are 010.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- No goldens change.
