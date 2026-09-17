# 076 — Global error and crash recovery screen

**Phase** 06 · Application shell  |  **Depends on** [021](../02-foundation/021-result-and-failures.md), [022](../02-foundation/022-logger-service.md), [033](../03-design-system/033-app-page.md), [040](../03-design-system/040-app-empty-state.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The last-resort screen the top-level `ErrorBoundary` renders. It offers exactly three ways forward — restart, export
the diagnostics log, open the recycle bin — and no way to destroy data.

Compose `AppPage` + `AppErrorState` (typed `Failure`). Title-bar actions stay icon-only; if a labelled command is
needed, put it in `AppPage.overflow` (075), never as a text button in the app bar.

## Files

- `frontend/lib/app/widgets/global_error_page.dart` (new)
- `frontend/lib/app/app.dart` (edit)

## Steps

1. Wrap `MaterialApp.router`'s `builder` in `ErrorBoundary` with this page as its fallback, so a build failure
   anywhere lands here. `TaptureApp` already owns theme and `routerProvider`; do not add a second `MaterialApp`.
2. Restart remounts the failed subtree under the existing `ProviderScope` (`ErrorBoundary`'s retry). It does not
   kill the process and does not discard unsaved work.
3. Export the log through `exportLog` and hand the file to the platform share sheet. The file is dated and
   device-named; redaction stays in `Logger`.
4. Recycle bin navigates through `AppRoutes.more` (the settings branch). State in plain language that the user's
   data is still on the device (`Copy.workStillOnDevice`). Offer no "clear data", no "reset" and no "reinstall".

## Constraints

- No control on this screen deletes, purges or resets anything (FE-SIMP-09, FE-SEC-08).
- The failure is rendered from a typed `Failure` through `AppErrorState`; this page writes no bespoke error copy
  (FE-CONS-11).

## Definition of done

- [x] A fatal build error renders this page instead of a red screen, with the app still running.
- [x] No path from this screen can destroy the user's work.
- [x] The exported log reaches a shareable file and contains no record values or credentials.
- [x] Tests: `frontend/test/app/widgets/global_error_page_test.dart` pumps a deliberately throwing subtree, asserts the
  three actions, asserts restart preserves unsaved state, and asserts no destructive action is present.
