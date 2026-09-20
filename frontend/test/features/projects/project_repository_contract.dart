import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';

import '../../support/factories.dart';

/// Create, watch and status-change contract shared by the Drift
/// implementation and the in-memory fake (FE-STATE-10).
void runProjectRepositoryContract(ProjectRepository Function() repository) {
  test('create is visible on watchAll', () async {
    final ProjectRepository repo = repository();
    _ok(await repo.create(aProject(name: 'Alpha')));
    final List<Project> rows = await repo.watchAll().first;
    expect(rows.single.name, 'Alpha');
    expect(rows.single.folderName, 'test-project');
  });

  test('create is visible on watchList with zero counts', () async {
    final ProjectRepository repo = repository();
    _ok(await repo.create(aProject(name: 'Alpha')));
    final List<ProjectListRow> rows = await repo.watchList().first;
    expect(rows.single.project.name, 'Alpha');
    expect(rows.single.recordCount, 0);
    expect(rows.single.unprocessedCount, 0);
    expect(rows.single.lastWorkedAt, rows.single.project.updatedAt);
  });

  test('watchHome on a new project is zero pending counts', () async {
    final ProjectRepository repo = repository();
    _ok(await repo.create(aProject(name: 'Alpha')));
    final ProjectHomeCounts counts = await repo.watchHome('project-1').first;
    expect(counts, emptyProjectHomeCounts);
  });

  test('watchAll hides archived rows unless includeArchived is set', () async {
    final ProjectRepository repo = repository();
    _ok(await repo.create(aProject()));
    _ok(await repo.setStatus('project-1', ProjectStatus.archived));
    expect(await repo.watchAll().first, isEmpty);
    expect(await repo.watchAll(includeArchived: true).first, hasLength(1));
  });

  test('setStatus moves a project off the default watch list', () async {
    final ProjectRepository repo = repository();
    _ok(await repo.create(aProject(name: 'Alpha')));
    expect((await repo.watchAll().first).single.name, 'Alpha');
    _ok(await repo.setStatus('project-1', ProjectStatus.archived));
    expect(await repo.watchAll().first, isEmpty);
    _ok(await repo.setStatus('project-1', ProjectStatus.active));
    expect((await repo.watchAll().first).single.name, 'Alpha');
  });

  test(
    'an empty name is a ValidationFailure, not a thrown Exception',
    () async {
      final ProjectRepository repo = repository();
      final Result<Project> created = await repo.create(aProject(name: ''));
      expect(_failure(created), isA<ValidationFailure>());
      expect(_failure(created).message, isNotEmpty);
      expect(_failure(created).recoveryAction, isNotEmpty);
    },
  );

  test('update and setStatus on a missing id are StorageFailure', () async {
    final ProjectRepository repo = repository();
    final Result<void> updated = await repo.update(aProject());
    expect(_failure(updated), isA<StorageFailure>());
    final Result<void> status = await repo.setStatus(
      'missing',
      ProjectStatus.archived,
    );
    expect(_failure(status), isA<StorageFailure>());
    expect(_failure(status).recoveryAction, isNotEmpty);
    final Result<void> pinned = await repo.setPinned('missing', true);
    expect(_failure(pinned), isA<StorageFailure>());
    expect(_failure(pinned).recoveryAction, isNotEmpty);
  });

  test('watchAll emits after create', () async {
    final ProjectRepository repo = repository();
    final Future<List<Project>> next = repo.watchAll().skip(1).first;
    _ok(await repo.create(aProject(name: 'Beta')));
    expect((await next).single.name, 'Beta');
  });

  test('watchList hides archived rows unless includeArchived is set', () async {
    final ProjectRepository repo = repository();
    _ok(await repo.create(aProject()));
    _ok(await repo.setStatus('project-1', ProjectStatus.archived));
    expect(await repo.watchList().first, isEmpty);
    expect(await repo.watchList(includeArchived: true).first, hasLength(1));
    expect(
      (await repo.watchList(includeArchived: true).first)
          .single
          .project
          .includedInDefaultExports,
      isFalse,
    );
  });

  test(
    'delete hides the project and is a StorageFailure when missing',
    () async {
      final ProjectRepository repo = repository();
      expect(_failure(await repo.delete('missing')), isA<StorageFailure>());
      _ok(await repo.create(aProject(name: 'Alpha')));
      _ok(await repo.delete('project-1'));
      expect(await repo.watchAll().first, isEmpty);
      expect(await repo.watchAll(includeArchived: true).first, isEmpty);
      expect(await repo.watchList().first, isEmpty);
    },
  );

  test('a rename leaves folderName unchanged', () async {
    final ProjectRepository repo = repository();
    _ok(await repo.create(aProject(name: 'Alpha')));
    _ok(await repo.update(aProject(name: 'Alpha Renamed')));
    final Project renamed = (await repo.watchAll().first).single;
    expect(renamed.name, 'Alpha Renamed');
    expect(renamed.folderName, 'test-project');
  });

  test('setPinned pins and unpins without changing updatedAt', () async {
    final ProjectRepository repo = repository();
    _ok(await repo.create(aProject(name: 'Alpha')));
    final DateTime updated = (await repo.watchAll().first).single.updatedAt;
    _ok(await repo.setPinned('project-1', true));
    final Project pinned = (await repo.watchAll().first).single;
    expect(pinned.pinnedAt, isNotNull);
    expect(pinned.updatedAt, updated);
    _ok(await repo.setPinned('project-1', false));
    final Project unpinned = (await repo.watchAll().first).single;
    expect(unpinned.pinnedAt, isNull);
    expect(unpinned.updatedAt, updated);
  });

  test('watchAll and watchList emit pinned rows first, then newest', () async {
    final ProjectRepository repo = repository();
    final DateTime olderAt = DateTime.utc(2026, 9, 17, 8);
    final DateTime newerAt = DateTime.utc(2026, 9, 17, 9);
    _ok(
      await repo.create(
        aProject(id: 'older', name: 'Older', updatedAt: olderAt),
      ),
    );
    _ok(
      await repo.create(
        aProject(id: 'newer', name: 'Newer', updatedAt: newerAt),
      ),
    );
    expect(
      (await repo.watchAll().first).map((Project row) => row.id).toList(),
      <String>['newer', 'older'],
    );
    expect(
      (await repo.watchList().first)
          .map((ProjectListRow row) => row.project.id)
          .toList(),
      <String>['newer', 'older'],
    );
    _ok(await repo.setPinned('older', true));
    expect(
      (await repo.watchAll().first).map((Project row) => row.id).toList(),
      <String>['older', 'newer'],
    );
    expect(
      (await repo.watchList().first)
          .map((ProjectListRow row) => row.project.id)
          .toList(),
      <String>['older', 'newer'],
    );
    _ok(await repo.setPinned('older', false));
    expect(
      (await repo.watchAll().first).map((Project row) => row.id).toList(),
      <String>['newer', 'older'],
    );
  });

  test('a pinned archived project stays behind includeArchived', () async {
    final ProjectRepository repo = repository();
    _ok(await repo.create(aProject(id: 'active', name: 'Active')));
    _ok(
      await repo.create(
        aProject(
          id: 'archived',
          name: 'Archived',
          status: ProjectStatus.archived,
        ),
      ),
    );
    _ok(await repo.setPinned('archived', true));
    expect(
      (await repo.watchAll().first).map((Project row) => row.id).toList(),
      <String>['active'],
    );
    expect(await repo.watchList().first, hasLength(1));
    expect(
      (await repo.watchAll(includeArchived: true).first)
          .map((Project row) => row.id)
          .toList(),
      <String>['archived', 'active'],
    );
    expect(
      (await repo.watchList(includeArchived: true).first)
          .map((ProjectListRow row) => row.project.id)
          .toList(),
      <String>['archived', 'active'],
    );
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

Failure _failure<T>(Result<T> result) {
  return switch (result) {
    FailureResult<T>(:final Failure failure) => failure,
    Success<T>() => throw TestFailure('expected a failure'),
  };
}
