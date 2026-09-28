# 087 — Arrange implementation flow and automatically synchronize progress

**Implementation step:** 01.02

**Phase** 01 · Project setup and guardrails  |  **Depends on** [001](001-project-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

**Implementation started:** Yes

## Implement

Give the plan one dependency-safe implementation order and one source of progress. Numbered folders are steps;
files within them are substeps, shown as `PP.SS`. Keep each existing three-digit task ID and filename so code,
commits and historical decisions retain their references. Backend and feature refinements precede Documentation;
whole-product hardening is the final folder. Test infrastructure is built before the final acceptance pass.

Derive Complete, Partially complete and Pending from each task's Definition of done and optional explicit started
marker. Aggregate the same states for folders. Show checked/total acceptance criteria, dependencies and the next
actionable unfinished task. Never infer completion from file existence, an implementation commit or elapsed time.

Generate the root tracker, ordered index, folder task tables and per-task execution positions through one
dependency-free Dart tool. New-task creation, verification and the repository pre-commit hook refresh those views;
CI checks committed drift before verification can repair it. Every implementation must update its acceptance
record and refresh the tracker before reporting completion, including backend-only and documentation changes.
The hook must preserve the user's staging choices and explain any required generated-file review.

Reconcile stale status claims with the current task records and concrete repository evidence. Preserve the old
tracker verbatim, including dated closure notes and carried decisions, in a clearly labelled historical snapshot.

Task [089](089-compact-progress-dashboard.md) later makes the root tracker a compact visual dashboard. Full
per-file acceptance/dependency tables remain in the index and folder READMEs; the tracker summarises completed
files and links partial/pending files without changing the source-of-truth or status rules.

## Files

- `AGENTS.md`, `dev-plan/README.md`, `dev-plan/STANDARD.md`, and frontend/backend workflow rules
- Numbered `dev-plan/` folders, task metadata and dependency links
- `dev-tracker.md`, `dev-plan/INDEX.md`, and generated blocks in phase READMEs
- `dev-plan/01-orchestration/history/README.md` and its `dev-tracker-2026-09-28.md` snapshot
- `frontend/tool/sync_dev_tracker.dart`, `check_staged_dev_tracker.dart`, `new_task.dart`, `check_plan.dart`,
  `verify.dart`, and `tool/hooks/pre-commit`
- Focused tests under `frontend/test/tool/` and the frontend CI workflow

## Contract

- `dart run tool/sync_dev_tracker.dart [--check] [--root <repo-root>]` runs from `frontend/`.
- Default mode validates the complete plan before updating generated files. Repeated runs are deterministic.
- `--check` performs no writes and fails on stale generated content or invalid task/dependency metadata.
- Only checked acceptance criteria prove completion. `**Implementation started:** Yes` makes a task with no
  checked criteria Partially complete; absence of the marker and checked criteria means Pending.
- A folder is Complete if every task is Complete, Pending if all are Pending, and Partially complete otherwise.
- A prerequisite must appear earlier in folder/substep order. Readiness remains separate from completion status.
- Pre-commit checks both the working tree and staged plan projection. Unstaged acceptance changes cannot be
  represented by staged generated summaries, and the hook never stages or discards user changes.

## Definition of done

- [x] Every task appears once in the ordered index with its folder step, substep and stable ID; the tracker covers every folder and links to file details (presentation refined by task 089).
- [x] Hardening is the last numbered folder; all declared prerequisites resolve and precede their dependants.
- [x] Task and folder summaries show the three states consistently, acceptance counts and actionable dependencies.
- [x] Historical closure notes and decisions are preserved; reconciled partial work includes evidence and open criteria.
- [x] One synchronizer refreshes summaries after task creation, verification and every installed pre-commit run; CI rejects committed drift.
- [x] Repository and workflow instructions require acceptance updates and tracker regeneration for every implementation.
- [x] Tests cover state aggregation, deterministic regeneration, read-only drift checks, invalid plans, task creation and safe hook staging; changed tooling passes targeted formatting and analysis.
- [x] The installed repository hook matches the managed hook, and the real plan passes synchronization and plan checks.
- [ ] The repository-wide verification gate passes as required by STANDARD.md, with remaining failures resolved rather than marked complete.

## Verification status

On 2026-09-28, all 96 focused tests passed across tracker synchronization, real pre-commit integration, task
creation, plan integrity, verification orchestration and hook installation. The hook fixtures verify docs/backend
commits, stale generated views, staged-versus-unstaged acceptance records, partial staging and preservation of
unrelated prose without auto-staging. Targeted analysis and formatting pass for the 11 changed Dart source/test
files; no new package is required.

At this task's verification, the plan had 27 ordered folders and 87 unique tasks, each represented in the generated views.
`check_plan.dart` passes; synchronization is deterministic and `--check` reports no drift after regeneration.
All live plan links resolve. The historical snapshot's SHA-256 matches its recorded original value.
The managed pre-commit and commit-message hooks were installed in this checkout and compared with their sources.

The repository-wide fast gate remains open. Its earlier run is recorded under
[task 079's verification status](../24-product-refinements/079-mobile-more-menu.md#verification-status): format,
analysis, allowlist, structure, test-presence and guardrail failures, plus an incomplete failing unit/widget run.
Those findings are outside this plan/tracker change and have not been repaired or treated as passing here.
This task remains Partially complete until the required whole-tree gate passes.
