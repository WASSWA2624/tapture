# 236 — Layout, accessibility and text-scale audit

**Phase** 23 · Hardening  |  **Depends on** [013](../01-orchestration/013-design-token-test.md), [017](../01-orchestration/017-accessibility-matchers.md), [047](../03-design-system/047-widget-gallery.md), [073](../06-app-shell/073-nav-shell.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One review pass driving every screen through the size-class matrix, the accessibility matchers and 200 percent text
scale, with each defect fixed in the screen or the design-system widget rather than waived.

## Files

- `frontend/test/responsive/` (new)
- `frontend/test/accessibility/` (new)

## Steps

1. Pump every primary screen through the responsive harness (018) at compact, medium and expanded widths in both
   orientations, asserting no overflow, no truncated label, correct two-pane behaviour and a reachable primary action.
2. Run the accessibility matchers (019) over the same screens and the widget gallery (082): 48dp targets, a label on
   every control, traversal order matching visual order, and measured contrast in light, dark and outdoor themes.
3. Repeat the whole matrix at 200 percent text scale, asserting no clipping, no overlap and no unreachable button.
4. Fix each failure where it belongs — a defect shared by several screens is fixed once in the design system, not
   patched per screen (FE-CONS-02).

## Constraints

- Features never measure the screen; size class comes from the shared breakpoint API (FE-RESP-02).
- No waiver list and no skipped screen: a failing screen is fixed (FE-A11Y-10).
- Contrast and target assertions run in all three themes (FE-A11Y-04, FE-THEME-10).

## Definition of done

- [ ] No screen overflows, hides its primary action, clips at maximum text scale, or carries an unlabelled control at
      any supported width, orientation or theme.
- [ ] A deliberately unlabelled icon button and a deliberately fixed-height row each fail the suite.
- [ ] Tests: `frontend/test/responsive/` widget tests capturing each screen at three widths in both orientations, and
      `frontend/test/accessibility/` assertions per screen including the 200 percent scale case.
