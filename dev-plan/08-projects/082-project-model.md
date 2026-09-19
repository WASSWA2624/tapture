# 082 — Project domain model and repository

**Phase** 08 · Projects  |  **Depends on** [052](../04-data-layer/052-projects-table.md), [062](../04-data-layer/062-repository-interfaces.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The immutable project model, its validated settings type, the mapper to and from the Drift row, the repository
implementation behind the interface declared in 111, the feature barrel and the fake every later project task tests
against. No presentation code in this phase or after it sees a database type.

## Files

- `frontend/lib/features/projects/domain/project.dart` (new)
- `frontend/lib/features/projects/domain/project_status.dart` (new)
- `frontend/lib/features/projects/domain/project_settings.dart` (new)
- `frontend/lib/features/projects/data/project_mapper.dart` (new)
- `frontend/lib/features/projects/data/project_repository_impl.dart` (new)
- `frontend/lib/features/projects/projects.dart` (new)
- `frontend/test/features/projects/fakes/fake_project_repository.dart` (new)

## Contract

```dart
enum ProjectStatus { active, archived, deleted }

final class Project {
  const Project({
    required this.id, required this.name, required this.status, required this.folderName,
    required this.settings, required this.createdAt, required this.updatedAt,
    this.description, this.organisation, this.startsOn, this.endsOn,
  });
  Project copyWith({String? name, String? description, String? organisation, ProjectStatus? status,
      DateTime? startsOn, DateTime? endsOn, ProjectSettings? settings});
}

/// Members the implementation fills in for the interface declared by task 062.
abstract interface class ProjectRepository {
  Stream<List<Project>> watchAll({bool includeArchived = false});
  Future<Result<Project>> create(Project project);
  Future<Result<void>> update(Project project);
  Future<Result<void>> setStatus(String id, ProjectStatus status);
}
```

## Steps

1. Model status, display name, description, organisation, start and end dates, settings and `folderName`. `folderName`
   is set at creation and has no setter and no `copyWith` entry.
2. `ProjectSettings` parses and serialises the row's validated JSON, rejecting unknown shapes and defaulting missing
   values rather than throwing.
3. Map both directions in `project_mapper.dart`; the repository implementation is the only file importing both the
   table and the domain.
4. Export from the barrel only `Project`, `ProjectStatus`, `ProjectSettings` and the repository provider; the mapper and
   the implementation stay internal.

## Constraints

- Nothing under `domain/` imports Flutter, Drift or a HTTP client (FE-STR-05).
- One public type per file, named after the type (FE-STR-06).
- The fake honours the same contract as the implementation, including the watch stream, so later screens never need a
  database (FE-STATE-10).

## Definition of done

- [x] Presentation compiles with no `core/db` import anywhere under `features/projects/presentation/`.
- [x] Unknown or missing settings JSON loads as defaults instead of throwing.
- [x] Tests: a round-trip mapper test row → `Project` → row; repository tests against an in-memory database for create,
  watch and status change; the same suite run against the fake.
