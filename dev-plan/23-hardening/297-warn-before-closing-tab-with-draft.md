# 297 — Warn before closing the tab with a draft

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On the web, closing or reloading the tab while a feedback draft holds work
shows the browser's own leave prompt. Cancelling it keeps the draft. Form
Close still folds in one tap.

## Files

- `frontend/lib/features/feedback/presentation/feedback_draft.dart`
- `frontend/lib/core/lifecycle/leave_guard.dart`
- `frontend/lib/core/lifecycle/leave_guard_web.dart`
- `frontend/lib/core/lifecycle/leave_guard_stub.dart`
- `frontend/lib/core/lifecycle/lifecycle.dart`
- `frontend/lib/main.dart`
- `frontend/lib/features/feedback/presentation/feedback_overlay.dart`
- `frontend/test/core/lifecycle/leave_guard_test.dart`
- `frontend/test/features/feedback/presentation/feedback_draft_controller_test.dart`
- `frontend/test/features/feedback/presentation/give_feedback_screen_test.dart`

## Constraints

- Browser access only through the core service with a fake (FE-STR-11).
- No new package; web uses `dart:js_interop` (FE-FLOW-06).
- `hasWork` is derived, never stored (FE-STATE-06).
- Release on dispose (FE-STATE-09). `core/` never imports `features/`
  (FE-STR-04).
- Exactly one prompt, and it is the browser's own (FE-SIMP-07, FE-SIMP-09).
- One-line docs on the new public API (FE-CODE-12). Fakes, not mocks
  (FE-TEST-01, FE-TEST-03).
- Do not persist drafts, and do not change native or desktop exit.

## Definition of done

- [x] Web: typed text, a named Other type or shots arm the browser leave
      prompt, including while the draft is folded or docked.
- [x] After a successful Save or a confirmed discard, closing the tab
      shows no prompt.
- [x] No prompt when no draft has been started, including after only
      opening the Feedback menu.
- [x] Native builds compile; the stub only records owners.
- [x] Tests: fake hold/release across two owners; `hasWork` false for a
      closed or empty open draft and true for text, Other name or a shot;
      typing arms the fake guard, Save and confirmed discard release it.
