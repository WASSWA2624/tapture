# 216 — Merge preview screen

**Phase** 19 · Bundles and merge  |  **Depends on** [038](../03-design-system/038-app-card.md), [213](213-merge-entity-level.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The screen that shows a `MergePlan` before anything is written: counts of new, updated, deleted, conflicting and
duplicate entities, each expandable to the entities behind it, with confirm and cancel as the only outcomes.

## Files

- `frontend/lib/features/merge/presentation/merge_preview_screen.dart` (new)

## Steps

1. Present the counts in the order and wording the specification's preview uses.
2. Name the source device and the bundle's creation time, so the operator knows what they are about to take in.
3. Confirm hands the plan to the apply step; cancel discards it.

## Constraints

- Nothing is written until confirmation, including no partial file copy (FE-STATE-07).
- Counts come from the plan; the screen recomputes nothing (FE-STATE-04).

## Definition of done

- [ ] Every category of the plan is shown with its count and can be expanded to the entities it covers.
- [ ] Cancelling leaves the project and its files entirely unchanged.
- [ ] Tests: widget test of `merge_preview_screen.dart` over a plan with every category populated, an empty plan and a load failure, plus an assertion that cancelling writes nothing.
