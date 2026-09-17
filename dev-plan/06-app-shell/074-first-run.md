# 074 — First-run flow

**Phase** 06 · Application shell  |  **Depends on** [023](../02-foundation/023-clock-service.md), [073](073-nav-shell.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One screen between install and first capture: an operator name, then "Start a project" with a shipped template. It is
skippable, and it is reached through a single gate in the router's guard chain, so task 267 can put sign-in in front
of it as a route change rather than a redesign (§56 rule 4, §71.1, FE-SIMP-04).

## Files

- `frontend/lib/features/onboarding/presentation/first_run_screen.dart` (new)
- `frontend/lib/app/route_guards.dart` (edit)

## Steps

1. Ask for an operator name only. Offer "Start a project" with a shipped template and "Skip"; skipping reaches
   capture with the name alone.
2. Record completion as one persisted flag the guard reads; the guard is one entry in `appGuards()`, not a second
   redirect.
3. Keep the name field the only input, so 498 replaces it with sign-in and enrolment without touching any screen
   after this one. No tour, no wizard, no second step, ever.

## Constraints

- One decision on the screen and one primary action (FE-SIMP-01, FE-SIMP-07).
- The device identifier comes from `device_identity.dart`; this screen creates no identity of its own (FE-STR-11).

## Definition of done

- [ ] A new install captures within thirty seconds of clearing this screen, having answered only the operator name.
- [ ] The gate is one entry in the router guard chain, so sign-in can precede it without editing a later screen.
- [ ] Skipping the project step still leaves a usable app.
- [ ] Tests: `frontend/test/features/onboarding/first_run_screen_test.dart` covers the skip path, the
  template path and the completed-flag short-circuit on second launch.

## Out of scope

- Sign-in, enrolment and role grants; task 267 adds them in front of this gate.
