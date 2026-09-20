# 004 — Add project pinning

**Feedback:** FBK0000006 · **Type:** Gap · **Priority:** P5 · **Effort:** M · **Depends on:** —

## Goal
A project can be pinned and unpinned, the pin survives a restart, and pinned projects sort above the
rest in every list that shows projects. This prompt delivers the storage, the model and the repository
only — no control and no visible change yet, so the risky step is reviewed on its own. 006 adds the
menu item and the list marker.

## Evidence
- FBK0000006: the reporter asks that each project row's more menu offer "pin (to pin the project)",
  beside archive, rename, open with and delete. `screenshots/FBK0000006-2.png` shows today's menu —
  Project details, Archive, Delete project — with no pin. Web, desktop, expanded, landscape, light.
- Root cause: nothing stores a pin.
  - `frontend/lib/core/db/tables/projects.dart:14-35` has `name`, `client`, `status`, `startedAt`,
    `completedAt`, `folderName` and `settings` — no pin column, and the only index is
    `projects_by_status` over `{status, updatedAt}`.
  - `frontend/lib/features/projects/domain/project.dart:11-23` has no pin field.
  - `listProjectsByStatus` (`projects.dart:76-96`) and `ProjectRepository.watchList`
    (`frontend/lib/features/projects/domain/project_repository.dart:43-45`) order by `updatedAt`
    descending only, so a pin would have nothing to sort by.
  - The schema is at version 13 (`frontend/lib/core/db/app_database.dart:36`), with steps 1-13 in
    `frontend/lib/core/db/migrations.dart:18-31` and `kDestructiveSteps` empty (`:35`).

## Scope
- Change:
  - `frontend/lib/core/db/tables/projects.dart`: add a nullable `DateTimeColumn get pinnedAt`. Extend
    the `projects_by_status` index, or add one, so "pinned first, then newest" is served by the index
    rather than sorted in Dart.
  - `frontend/lib/core/db/migrations.dart` and `app_database.dart`: add `migrateToV14` adding the
    column, bump `kSchemaVersion` to 14, leave `kDestructiveSteps` empty — the step adds a nullable
    column and rewrites nothing.
  - `frontend/lib/features/projects/domain/project.dart`: a nullable `pinnedAt`, defaulting to null in
    `copyWith` and the factories.
  - `frontend/lib/features/projects/domain/project_repository.dart` and its implementation: a
    `setPinned(String id, bool pinned)` that writes only that column, and ordering in `watchAll` and
    `watchList` that puts pinned rows first, then `updatedAt` descending.
  - `frontend/test/factories/`: the project factory gains an optional pin.
  - Tests, listed in the steps.
- Do not change: any screen, any menu, `ProjectStatus`, archive, delete, the folder tree, or the
  merge and tombstone columns. No UI in this prompt.

## Rules
- FE-STATE-07 and the first of the five: a migration adds; it never rewrites or destroys. Earlier
  upgrade steps are never edited, and `id`, `createdAt`, `updatedAt`, `updatedByDevice` and `rev` are
  never back-filled (`migrations.dart:14-16`).
- FE-STR-05: the domain stays pure Dart; the pin is a domain field, and Drift stays in `data/`.
- FE-STR-04: `presentation -> domain <- data`.
- FE-PERF-03 and FE-CONS-09: order in the query, never by sorting a materialised list in Dart.
- FE-TEST-02 and FE-TEST-04: repository and DAO tests against an in-memory database; one-line fixtures.
- FE-TEST-10: an interrupted upgrade leaves the database usable and the data intact.
- FE-FLOW-08: the work is a plan task before it is code.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 08-projects add-project-pinning "Add project pinning"`
   (FE-FLOW-08).
2. **Stop for the review below.**
3. Add the column and `migrateToV14`; bump the schema version; add or extend the index.
4. Add the domain field, `setPinned`, and the pinned-first ordering.
5. Tests:
   - `frontend/test/core/db/migrations_test.dart`: a version-13 database with projects upgrades to 14
     with every row intact and `pinnedAt` null; the step is not in `kDestructiveSteps`; a second run is
     a no-op.
   - `frontend/test/features/projects/data/project_repository_impl_test.dart`: `setPinned` writes only
     the pin; `watchList` and `watchAll` emit pinned rows first, then newest, with ties stable;
     unpinning restores the plain order; pinning an archived project keeps it behind `includeArchived`.
   - A query-plan or explain assertion that the ordering uses the index (FE-TEST-09).

## Human review
⛔ Stop before step 3 and ask:
- Is a pin shared with everyone who opens the project, or is it this device's own shortcut? A shared pin
  belongs on the `Projects` row and merges like any other column; a device-local pin belongs in the
  settings store and never syncs. **Recommendation: a shared `pinnedAt` column on `Projects`**, because
  the reporter describes it beside archive and rename, which are project state, and a column is
  reversible where a settings key is easy to strand.
- Should pinning bump `updatedAt` and the merge revision? **Recommendation: no** — a pin is not work on
  the project, and bumping it would reorder "Last worked" and create merge churn.

Proceed only with an explicit answer. If the answer is "proceed", do both recommendations. Do not run
step 3 before an answer: the schema version is public once it ships.

## Acceptance criteria
- [ ] A database at version 13 upgrades to 14 with every project row intact and `pinnedAt` null.
- [ ] `setPinned` pins and unpins, and the value survives a restart.
- [ ] `watchList` and `watchAll` emit pinned projects first, then newest first, with a stable tie order.
- [ ] Pinning changes neither `updatedAt`, nor the merge revision, nor "Last worked" (unless the review
      answer says otherwise).
- [ ] Archived and deleted projects still obey `includeArchived` and the status filter when pinned.
- [ ] The ordering is served by an index, not by a Dart sort.
- [ ] No screen changes; the existing project goldens are untouched.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- No goldens are regenerated. A changed golden means UI crept into this prompt.
