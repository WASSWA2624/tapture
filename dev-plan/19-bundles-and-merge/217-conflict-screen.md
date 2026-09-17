# 217 — Conflict resolution, one at a time and in bulk

**Phase** 19 · Bundles and merge  |  **Depends on** [182](../16-review/182-evidence-viewer.md), [213](213-merge-entity-level.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The screen that settles what the rules could not: each conflict shown with both values, their authors, their timestamps
and their evidence, resolved as keep mine, take theirs, type a value or decide later — plus the two bulk actions for
operators facing hundreds of them.

## Files

- `frontend/lib/features/merge/presentation/conflict_screen.dart` (new)
- `frontend/lib/features/merge/presentation/conflict_bulk_actions.dart` (new)

## Steps

1. Show one conflict at a time with the evidence viewer of 338 available for either side.
2. Offer "apply to all remaining conflicts on this field" and "prefer this device for the rest".
3. Write each resolution — including every one implied by a bulk action — as its own audit entry naming the chooser.
4. Leave a decide-later conflict unresolved on the record and block approval of that record until it is settled.

## Constraints

- One decision at a time; bulk actions are an explicit second control, never the default (FE-SIMP-07).
- Typing a value is a normal field edit and passes the field's validation (FE-SEC-06).

## Definition of done

- [ ] All four choices resolve a conflict, and typing a value is validated like any other edit.
- [ ] A record with an unresolved conflict cannot be approved.
- [ ] A bulk action appears in the audit log as one entry per conflict it settled, not as a single line.
- [ ] Tests: widget tests of `conflict_screen.dart` over each of the four choices and the four states, and of `conflict_bulk_actions.dart` asserting per-conflict audit entries.
