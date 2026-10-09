# 159 — Diagnose the baseline context hierarchy drag reorder failure

**Depends on** [011](../11-context.md)

## Implement

Reproduce the three-level hierarchy drag-reorder failure on the task-158 baseline `d921abb0`, diagnose whether drag geometry or production reordering is responsible, and correct the confirmed cause. Preserve the expected `[c, a, b]` order and repository persistence assertion; do not weaken them to match the observed `[a, c, b]` result.

## Files

- `frontend/test/features/context/presentation/context_screens_test.dart`
- `frontend/lib/features/context/presentation/context_hierarchy_screen.dart`

## Definition of done

- [ ] The baseline failure has a reproducible trigger and diagnosed cause.
- [ ] Tests verify actual pointer reordering and persisted order for upward/downward moves, including narrow and scaled layouts.
- [ ] The existing context presentation suite passes; analysis, tracker synchronization and plan checks pass.

## Evidence

2026-10-09: task 158 reproduced the existing failure before implementing Capture setup, both in the affected baseline run and in isolation. The unchanged assertion continues to fail after implementation. No correction is included in task 158.
