# 089 — Show a concise visual development tracker

**Implementation step:** 01.04

**Phase** 01 · Project setup and guardrails  |  **Depends on** [001](001-project-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

**Implementation started:** Yes

## Implement

Make `dev-tracker.md` a concise generated dashboard: overall completed-file progress, status totals, next actionable
task and one row per implementation folder. Show visual bars with exact completed/total counts and linked partial
and pending task IDs. Keep full per-file acceptance/dependency details in the index and folder READMEs.

Compute completion only from fully complete tasks, without estimating partial effort. Keep unfinished prerequisites
visible independently of completion. Preserve automatic regeneration, source checklists, history links, stable IDs
and the existing ordered plan, with hardening last.

## Files

- `frontend/tool/sync_dev_tracker.dart` and affected tracker/new-task/hook tests
- `dev-tracker.md` and generated plan views
- `dev-plan/README.md`, `STANDARD.md`, `AGENTS.md` and task 087's superseded tracker-presentation notes

## Definition of done

- [x] The root tracker uses one folder table, overall progress bars/counts and a compact legend instead of duplicating every task section.
- [x] Every unfinished task is linked under its actual state; full completed-task details and dependencies remain in the index and folder READMEs.
- [x] Percentages/bars count only completed files, handle empty/all-complete boundaries, preserve next-action dependencies and flag completed scopes with unfinished prerequisites.
- [x] Focused tracker/generator/hook tests, targeted formatting/analysis, plan validation and deterministic synchronization checks pass.
- [ ] The repository-wide verification gate required by STANDARD.md passes; existing failures remain open until resolved.

## Verification

54 focused tests passed across tracker generation, task creation and real pre-commit integration. They cover
unweighted file counts, flooring, empty/all-complete bars, one row per folder, partial/pending links, full index
retention, prerequisite warnings, next work and automatic refresh. Changed Dart source/tests pass targeted analysis
and formatting. Plan validation passes for 89 tasks; deterministic regeneration and read-only drift checks pass.

The existing whole-repository gate failures recorded in [079](../24-product-refinements/079-mobile-more-menu.md#verification-status)
remain unresolved. This presentation change does not rerun or claim success for that gate; its acceptance remains open.
