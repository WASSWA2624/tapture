# 076 — Global error and crash recovery screen

**Phase** 06 · Application shell  |  **Depends on** [021](../02-foundation/021-result-and-failures.md), [022](../02-foundation/022-logger-service.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The last-resort screen the top-level `ErrorBoundary` renders. It offers exactly three ways forward — restart, export
the diagnostics log, open the recycle bin — and no way to destroy data.

## Files

- `frontend/lib/app/widgets/global_error_page.dart` (new)
- `frontend/lib/app/app.dart` (edit)

## Steps

1. Wrap the router's builder in `ErrorBoundary` with this page as its fallback, so a build failure anywhere lands here.
2. Restart rebuilds the provider scope rather than killing the process, so nothing unsaved is discarded.
3. Export the log through `exportLog` and hand the file to the platform share sheet.
4. State in plain language that the user's data is still on the device. Offer no "clear data", no "reset" and no
   "reinstall" action.

## Constraints

- No control on this screen deletes, purges or resets anything (FE-SIMP-09, FE-SEC-08).
- The failure is rendered from a typed `Failure` through `AppErrorState`; this page writes no bespoke error copy
  (FE-CONS-11).

## Definition of done

- [ ] A fatal build error renders this page instead of a red screen, with the app still running.
- [ ] No path from this screen can destroy the user's work.
- [ ] The exported log reaches a shareable file and contains no record values or credentials.
- [ ] Tests: `frontend/test/app/widgets/global_error_page_test.dart` pumps a deliberately throwing subtree, asserts the
  three actions, asserts restart preserves unsaved state, and asserts no destructive action is present.
