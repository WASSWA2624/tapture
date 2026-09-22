# 043 — Align the feedback shot controls

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Give us feedback stacks Attach and Include the feedback UI as matching
checkboxes, then a start-aligned row of capture buttons. The capture names
are Screenshot current screen and Screenshot external window, including on
the Feedback menu.

## Files

- `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/feedback/presentation/feedback_shots.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

## Constraints

- Reuse `AppSwitchTile.checkbox` and `AppIconButton` (FE-CONS-01).
- Strings stay in `Copy`; keys keep their meaning (FE-L10N-01, FE-L10N-02).
- No width checks; stacking works at every width (FE-RESP-02).
- 48dp targets, labelled (FE-A11Y-01, FE-A11Y-02). Spacing uses `Space.*`
  (FE-THEME-01).
- Do not change capture behaviour, the include-UI default, `maxShots`, the
  gallery, `AppSwitchTile`, or `AppIconButton`.

## Definition of done

- [x] Include the feedback UI is a checkbox like Attach N images, off by
      default; ticking it still captures the feedback chrome.
- [x] Tooltips and labels read Screenshot current screen and Screenshot
      external window; the still is labelled External window.
- [x] At 360 dp, neither checkbox label wraps; at 200 percent text the
      section does not overflow.
- [x] The docked panel shows both checkboxes above the capture row.
- [x] Tests: include-UI found by text; one-line labels at 360 dp; no
      overflow at 360 dp / 200 percent; docked order.
