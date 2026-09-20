# 327 — Add project pinning

**Phase** 08 · Projects  |  **Depends on** [082](082-project-model.md), [083](083-project-list.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A project can be pinned and unpinned. The pin is a shared `pinnedAt` column, survives a restart, and
does not bump `updatedAt` or the merge revision. Every project list orders pinned rows first, then
newest `updatedAt`, with a stable `id` tie. No control and no visible change — 006 adds the menu
item and the list marker.

## Files

- `frontend/lib/core/db/tables/projects.dart`
- `frontend/lib/core/db/migrations.dart`
- `frontend/lib/core/db/app_database.dart`
- `frontend/lib/features/projects/domain/project.dart`
- `frontend/lib/features/projects/domain/project_repository.dart`
- `frontend/lib/features/projects/data/project_mapper.dart`
- `frontend/lib/features/projects/data/project_repository_impl.dart`
- `frontend/test/support/factories.dart`
- `frontend/test/features/projects/fakes/fake_project_repository.dart`
- `frontend/test/core/db/migrations_test.dart`
- `frontend/test/core/db/tables/projects_test.dart`
- `frontend/test/features/projects/data/project_repository_impl_test.dart`
- `frontend/test/features/projects/data/project_mapper_test.dart`

## Constraints

- A migration adds; it never rewrites or destroys. Do not edit earlier upgrade steps (FE-STATE-07).
- Domain stays pure Dart; Drift stays in `data/` (FE-STR-05, FE-STR-04).
- Order in the query, never by sorting a materialised list in Dart (FE-PERF-03, FE-CONS-09).
- Pinning writes only `pinnedAt` and leaves `updatedAt`, `rev` and "Last worked" alone.
- Do not change any screen, menu, `ProjectStatus`, archive, delete, the folder tree, or merge
  columns. No UI, no golden regeneration.

## Definition of done

- [x] A version-13 database with projects upgrades to 14 with every row intact and `pinnedAt` null,
      on the native file database and on an in-memory database.
- [x] `setPinned` pins and unpins; the value survives a close and reopen.
- [x] `watchList` and `watchAll` emit pinned first, then newest, with a stable tie; unpinning
      restores the plain order; a pinned archived row stays behind `includeArchived`.
- [x] The ordering is served by `projects_by_status_pin`.
- [x] `migrateToV14` is not in `kDestructiveSteps`; a second run is a no-op.
- [x] Tests: migration 13→14, repository pin/order, query-plan uses the index.
