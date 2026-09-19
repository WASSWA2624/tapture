# 306 — Keep the feedback bar above the keyboard

**Phase** 23 · Hardening  |  **Depends on** [282](282-in-app-feedback.md), [283](283-feedback-dictation-and-layout.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

When Give us feedback is folded into its bar, typing or dictating in the bar
keeps the bar in view, just above the on-screen keyboard. With no keyboard
the resting place is unchanged.

## Files

- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

## Constraints

- No layout assumes the keyboard is closed (FE-RESP-06).
- Insets are handled once, in the shell-level overlay (FE-RESP-08).
- Portrait, landscape, and 200 percent text (FE-RESP-07, FE-A11Y-03).
- No literal offsets; reuse `Sizes.minTapTarget` and the theme navigation
  bar height (FE-THEME-01, FE-CODE-09).
- No `setState`; `MediaQuery` drives the rebuild. Only the positioned bar
  depends on the inset (FE-STATE-01, FE-PERF-05).
- Pump to a condition; never a fixed delay (FE-TEST-07).
- Do not change the unfolded form, the docked panel, the floating button,
  `FeedbackDraftBar` content, `AndroidManifest.xml`, or the navigation bar.

## Definition of done

- [x] The folded bar's `bottom` is the larger of the resting offset and the
      keyboard inset.
- [x] Phone, medium, expanded, landscape, and 200 percent text keep the bar
      fully above the keyboard, with a hit-testable field.
- [x] Closing the keyboard returns the compact bar above the navigation bar.
- [x] Typed text survives opening and closing the keyboard.
- [x] Tests: the cases above, pumped through `FakeViewPadding`.
