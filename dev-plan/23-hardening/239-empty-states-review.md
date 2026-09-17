# 239 — Empty-state coverage test

**Phase** 23 · Hardening  |  **Depends on** [040](../03-design-system/040-app-empty-state.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The suite that fails when a collection or detail screen renders nothing useful with no data, plus the fix for every
screen it catches.

## Files

- `frontend/test/states/empty_state_coverage_test.dart` (new)

## Contract

```dart
Future<void> expectEmptyState(WidgetTester t, {required String action});
```

## Steps

1. Enumerate every screen that renders a collection, pump each against an empty repository fake, and assert the shared
   empty state (068) with a primary action is shown.
2. Replace every bespoke "nothing here" string found with the shared widget, and give each one an action naming what to
   do next.

## Constraints

- Empty tells the operator what to do next, never merely that there is nothing (FE-SIMP-11).
- The screen list is derived from the router, so a new collection screen is covered without editing the test
  (FE-CONS-04).

## Definition of done

- [ ] A new collection screen without an empty state fails the suite.
- [ ] Every empty state names its next action, and none renders a bare message.
- [ ] Tests: the coverage test itself, one case per collection screen, plus a fixture screen proving the matcher fails
      when the empty state is missing.
