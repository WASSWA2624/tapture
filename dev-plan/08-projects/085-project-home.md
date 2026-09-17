# 085 — Project home screen

**Phase** 08 · Projects  |  **Depends on** [038](../03-design-system/038-app-card.md), [075](../06-app-shell/075-status-line.md), [083](083-project-list.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The screen that answers "what should I do next" for the open project: counts, the current context, one dominant
"Continue capturing" action, and a secondary row of `AppCard`s for Review, Process, Export and Share each showing its
pending count. Every number is a link to the list it counts.

## Files

- `frontend/lib/features/projects/presentation/project_home_screen.dart` (new)

## Steps

1. Read the project from `currentProjectDetailsProvider`; the screen holds no id of its own.
2. Place "Continue capturing" as the single primary action in the lower third, within thumb reach on a large phone.
3. Derive every count from watch queries and route each one through `AppRoutes` to its filtered list.
4. Show the current context in the header; the pending totals stay in the global status line rather than being repeated
   verbatim here.

## Constraints

- Exactly one primary action; the secondary row is visibly subordinate (FE-SIMP-01, FE-A11Y-09).
- Counts are derived, never stored, so they cannot disagree with the lists they link to (FE-STATE-06).

## Definition of done

- [ ] Every number on the screen is tappable and lands on the matching list, already filtered.
- [ ] One primary action, in the lower third, usable one-handed.
- [ ] Loading, empty, populated and failure all render through `AsyncValueView`.
- [ ] Tests: widget tests of all four states, plus a navigation test asserting each count reaches its route with the
  right filter.
