# 003 — Dock feedback panel beside app

**Feedback:** FBK0000003 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **Depends on:** —

## Goal
On expanded desktop, Give us feedback sits beside the working screen. The screen in action is not
covered, dimmed, or clipped by the panel. Compact and medium still take the full screen. Light, dark
and outdoor keep the same geometry (FE-THEME-03).

## Evidence
- FBK0000003: on desktop the working screen must not be shadowed by Give us feedback. Web, expanded
  (1280×585), landscape.
- Root cause: `feedback_overlay.dart` paints the docked panel in a `Stack` with
  `PositionedDirectional(end: 0, width: AppConstants.userFeedback.panelWidth)` over a full-width
  `RepaintBoundary` child. Task 283 asked for a side panel beside a usable app; the test
  `on a wide window the form docks beside a usable app` only checks a centred `App screen` label,
  which stays left of the 420dp panel even when the scaffold extends underneath.

## Scope
- Change: `FeedbackOverlay` layout when `docked` (`expanded && SizeClass.expanded`): `Row` with
  `Expanded` child then a trailing panel of `AppConstants.userFeedback.panelWidth`. Keep the
  `RepaintBoundary` on the app child only so screenshots exclude the form. Trailing outline hairline
  stays token-based.
- Do not change: compact/medium `Positioned.fill` form; draft bar; FAB hiding while expanded;
  screenshot capture; panel width token.

## Rules
- FE-RESP-02: no `MediaQuery` width; keep `context.sizeClass`.
- FE-L10N-05: trailing edge (`Row` + `BorderDirectional.start` on the panel), not left/right.
- FE-THEME-01, FE-CODE-09: `AppConstants.userFeedback.panelWidth`, outline from tokens.
- FE-PERF-05: do not rebuild the shell when the draft text changes (existing `select` on fold).
- FE-TEST-01, FE-A11Y-03.

## Steps
1. Record the work: extend 283, or
   `cd frontend && dart run tool/new_task.dart 23-hardening dock-feedback-panel-beside-app "Dock feedback panel beside app"`.
2. Replace the docked `PositionedDirectional` overlay with a `Row` (`Expanded` app + panel).
3. Tighten `give_feedback_screen_test.dart`: put `App screen` at `AlignmentDirectional.centerEnd` (or
   a full-width child whose right edge must be `<= form.left`). Tapping `App screen` must still hit
   the app, not the form. Width 1400 stays expanded (1024+).
4. Confirm compact (400) still fills the window with the form.

## Acceptance criteria
- [ ] Expanded: app right edge ≤ panel left edge; no shared pixels.
- [ ] Expanded: the operator can tap the screen in action; the panel does not intercept those taps.
- [ ] Compact and medium: the form still fills the overlay; the FAB hides while expanded.
- [ ] Screenshots still capture the app child without the form.
- [ ] 200 percent text on expanded does not clip the panel or the app (FE-A11Y-03).

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- No goldens unless the overlay is snapshotted; none exist today.
