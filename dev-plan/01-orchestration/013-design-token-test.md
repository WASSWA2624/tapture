# 013 — Design-token and responsive boundary tests

**Phase** 01 · Project setup and guardrails  |  **Depends on** [004](004-folder-scaffold.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Two architecture suites over `frontend/lib/features/`: `tokens_test.dart` fails a hardcoded colour, spacing, radius,
duration or text style, and `responsive_test.dart` fails a screen that measures the window itself.

## Files

- `frontend/test/architecture/tokens_test.dart` (new)
- `frontend/test/architecture/responsive_test.dart` (new)

## Steps

1. In `tokens_test.dart`, scan `frontend/lib/features/` for `Color(`, `Colors.`, `EdgeInsets.all(` with a literal, `BorderRadius.circular(` with a literal, `Duration(` and `TextStyle(`.
2. Allow those constructs only under `frontend/lib/app/theme/` and `frontend/lib/core/widgets/`.
3. Emit the token that should have been used in each violation message.
4. In `responsive_test.dart`, fail on any comparison of `MediaQuery` size or width outside `frontend/lib/core/widgets/responsive/`.
5. Fail on a hardcoded pixel width above the token maximum in a feature widget, naming the `SizeClass` accessor to use instead.

## Constraints

- Colour, spacing, radius, elevation, duration and text style come from the token files; a literal in `lib/features/` fails the build (FE-THEME-01).
- The 600dp and 1024dp breakpoints exist only inside `SizeClass`, and features never compare `MediaQuery` width (FE-RESP-01, FE-RESP-02).
- Numbers and durations come from tokens or `AppConstants`, never from a call site (FE-CODE-09).

## Definition of done

- [x] A literal colour added to a feature widget fails `tokens_test.dart`; the same literal under `frontend/lib/app/theme/` passes.
- [x] A screen comparing screen width fails `responsive_test.dart`; the same comparison under `frontend/lib/core/widgets/responsive/` passes.
- [x] Every violation message names the replacement token or `SizeClass` accessor, not just the offending line.
- [x] Tests: both suites, each with an allowed-location and a forbidden-location fixture under `frontend/test/architecture/fixtures/`.
