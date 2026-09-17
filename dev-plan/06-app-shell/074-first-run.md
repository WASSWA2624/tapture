# 074 — First-run flow

**Phase** 06 · Application shell  |  **Depends on** [023](../02-foundation/023-clock-service.md), [033](../03-design-system/033-app-page.md), [034](../03-design-system/034-app-button.md), [035](../03-design-system/035-app-text-field.md), [046](../03-design-system/046-copy-helper.md), [073](073-nav-shell.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One screen between install and first capture: an operator name, then "Start a project" with a shipped template. It is
skippable, and it is reached through a single gate in the router's guard chain, so task 267 can put sign-in in front
of it as a route change rather than a redesign (§56 rule 4, §71.1, FE-SIMP-04).

The screen composes `AppPage` + `AppBrandLockup` + `AppTextField` + `AppPrimaryAction` + text `AppButton`. Copy comes
from `Copy.firstRun*`. Compact uses the branded header fill; wider classes keep the same widgets in a readable column.

## Files

- `frontend/lib/features/onboarding/presentation/first_run_screen.dart` (new)
- `frontend/lib/app/route_guards.dart` (edit — `_firstRun` is the first `appGuards()` entry)

## Contract

```dart
class FirstRunScreen extends ConsumerStatefulWidget { const FirstRunScreen({super.key}); }

class FirstRunSnapshot { final bool completed; final bool busy; /* operator name */ }
final firstRunProvider; // TextStore flag `firstRun`; test helper firstRunCompletedOverride()
```

`_firstRun` (already declared in 072): if the flag is down and the path is not `/first-run` (and not debug
`/_gallery`), redirect to `AppRoutes.firstRun`. If the flag is up and the path is `/first-run`, redirect to capture.

## Steps

1. Ask for an operator name only. Offer `Copy.firstRunStartProject` (`AppPrimaryAction`, caption
   `Copy.firstRunStartCaption`) and `Copy.firstRunSkip` (text `AppButton`). Both stay disabled until the field is
   non-empty. Skipping reaches capture with the name alone.
2. Record completion as one persisted `TextStore` flag the guard reads. The notifier is private in the screen file
   so the file still holds one public class (FE-STR-06); export a test `Override` for completed-flag suites.
3. Keep the name field the only input, so 498 replaces it with sign-in and enrolment without touching any screen
   after this one. No tour, no wizard, no second step, ever.
4. Title-bar actions on this `AppPage`, if any, stay icon-only. Labelled commands belong in `overflow` (075), not
   beside the title.

## Constraints

- One decision on the screen and one primary action (FE-SIMP-01, FE-SIMP-07).
- The device identifier comes from `device_identity.dart`; this screen creates no identity of its own (FE-STR-11).
- Strings from `Copy`; tokens only (FE-L10N-01, FE-THEME-01).

## Definition of done

- [x] A new install captures within thirty seconds of clearing this screen, having answered only the operator name.
- [x] The gate is one entry in the router guard chain, so sign-in can precede it without editing a later screen.
- [x] Skipping the project step still leaves a usable app.
- [x] Tests: `frontend/test/features/onboarding/presentation/first_run_screen_test.dart` covers the skip path, the
  template path and the completed-flag short-circuit on second launch.

## Out of scope

- Sign-in, enrolment and role grants; task 267 adds them in front of this gate.
