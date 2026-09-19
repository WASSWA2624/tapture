# 003 — Keep the feedback bar above the keyboard

**Feedback:** FBK0000005 · **Type:** Defect · **Priority:** P3 · **Effort:** S · **Depends on:** —

## Goal
When Give us feedback is folded into its bar, typing or dictating in the bar keeps the bar in view,
just above the on-screen keyboard. This holds on any screen of the app and at compact, medium and
expanded widths, in portrait and landscape, in light, dark and outdoor, and at 200 percent text.

## Evidence
- FBK0000005: on mobile, when the feedback form is minimised, or while the reporter moves to another
  screen to screenshot it, the feedback field should stay visible above the keyboard when typing or using
  speech to text. No image. Android, mobile, compact, portrait (393x886 dp), system dark, text scale 1.
- Root cause: `frontend/lib/features/feedback/presentation/feedback_overlay.dart:148-159` places
  `FeedbackDraftBar` with `bottom:` set to the navigation bar height plus `viewPaddingOf(context).bottom`
  on compact, and `0` elsewhere. The overlay's `Stack` wraps the shell `Scaffold`
  (`frontend/lib/app/nav_shell.dart:25`), so nothing resizes it for the keyboard, and the offset ignores
  `MediaQuery.viewInsetsOf(context).bottom`. The keyboard (usually about 300 dp) therefore covers the
  bar, which sits about 80 dp from the bottom.
- The unfolded form is fine: `AppPage` builds a `Scaffold` with `resizeToAvoidBottomInset: true`
  (`frontend/lib/core/widgets/app_page.dart:94-98`).

## Scope
- Change:
  - `frontend/lib/features/feedback/presentation/feedback_overlay.dart`: compute the bar's `bottom` as
    the larger of today's resting offset and `MediaQuery.viewInsetsOf(context).bottom`, so the bar rides
    on top of the keyboard and returns to its resting place when the keyboard closes.
  - `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`: the tests below.
- Do not change: the unfolded form, the docked panel, the floating Feedback button's position,
  `FeedbackDraftBar`'s content, `AndroidManifest.xml` (`adjustResize` stays), or the navigation bar.

## Rules
- FE-RESP-06: no layout assumes the keyboard is closed.
- FE-RESP-08: insets are handled once, in the shell-level overlay, not in each screen.
- FE-RESP-07 and FE-A11Y-03: portrait and landscape, and 200 percent text.
- FE-THEME-01 and FE-CODE-09: no literal offsets; reuse `Sizes.minTapTarget` and the theme's navigation
  bar height, as today.
- FE-STATE-01: no `setState`; `MediaQuery` drives the rebuild. FE-PERF-05: only the positioned bar
  depends on the inset.
- FE-TEST-07: pump to a condition, and never use a fixed delay.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 23-hardening keep-feedback-bar-above-keyboard "Keep the feedback bar above the keyboard"`
   (FE-FLOW-08).
2. In `_FeedbackOverlayState.build`, read `MediaQuery.viewInsetsOf(context).bottom` and use
   `math.max(resting, inset)` for the `PositionedDirectional.bottom` of the bar. `SafeArea` inside the
   bar already drops the gesture inset while the keyboard covers it. Confirm this in the test instead
   of adding padding.
3. Add tests with `tester.view.viewInsets = FakeViewPadding(bottom: …)`:
   - "the folded bar sits above an open keyboard on a phone": 393x886 dp, a 300 dp inset. The bar's
     rect ends at or above the keyboard's top edge, and its text field is hit-testable.
   - the same at a medium width (700 dp) and an expanded width (1280 dp) with the draft folded;
   - landscape at 886x393 dp with a 200 dp inset: the bar is fully visible;
   - 200 percent text: the taller bar is still fully above the keyboard;
   - "closing the keyboard returns the bar above the navigation bar": the existing resting position is
     unchanged;
   - typed text survives opening and closing the keyboard.

## Acceptance criteria
- [ ] Phone, portrait: with the draft folded, focusing the bar's field shows the whole bar directly above
      the keyboard on every shell screen.
- [ ] Dictating from the bar's microphone keeps the bar in view, whether or not the keyboard is open.
- [ ] Landscape and 200 percent text: the bar stays fully visible above the keyboard, with no overflow.
- [ ] Medium and expanded widths behave the same when the draft is folded.
- [ ] With no keyboard, the bar's position is unchanged: above the navigation bar on compact, at the
      bottom elsewhere.
- [ ] Light, dark and outdoor look identical apart from colour (FE-THEME-03).
- [ ] FBK0000005 is resolved.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- On an Android phone: fold the draft, open Projects, and tap the bar's field; the bar sits on the
  keyboard. Repeat in landscape.
- No goldens change.
