# 322 — Show a single feedback image as a thumbnail

**Phase** 23 · Hardening  |  **Depends on** [282](282-in-app-feedback.md), [283](283-feedback-dictation-and-layout.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

In Give us feedback, one attached image is a square thumbnail, the same kind of tile several
images use, instead of filling the form's width. A tap still opens the full preview.

## Files

- `frontend/lib/features/feedback/presentation/feedback_shots.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

## Constraints

- Thumbnails in the form, and full images only in the viewer. Decode at the drawn size
  (`cacheWidth`), as the tile already does (FE-CONS-06, FE-PERF-04).
- Ratios and `BoxFit.cover`, not pixel sizes. Nothing stretches edge to edge
  (FE-RESP-09, FE-RESP-04).
- Start alignment mirrors in right-to-left (FE-L10N-05).
- The tile and its remove control keep 48 dp targets and labels (FE-A11Y-01, FE-A11Y-02).
- Tokens only; `galleryTile` already exists in `AppConstants` (FE-THEME-01).
- Do not change the preview dialog, the remove control, the image cap, the attach and
  include-UI checkboxes, or how several images lay out.

## Definition of done

- [x] One attached image shows as a thumbnail of about 160 dp, not a full-width picture.
- [x] Tapping the thumbnail opens the large preview, and its X removes it.
- [x] Two or more images look as they do today.
- [x] Tests: with one image, at 393 dp and at the 420 dp docked panel width, the tile is
      square and no wider than `galleryTile`; tapping it opens the preview at full width;
      with three images, the layout is unchanged; no overflow at 200 percent text.
