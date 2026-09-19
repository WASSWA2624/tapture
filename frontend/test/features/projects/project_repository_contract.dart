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
  });

  test('watchAll emits after create', () async {
    final ProjectRepository repo = repository();
    final Future<List<Project>> next = repo.watchAll().skip(1).first;
    _ok(await repo.create(aProject(name: 'Beta')));
    expect((await next).single.name, 'Beta');
  });

  test('a rename leaves folderName unchanged', () async {
    final ProjectRepository repo = repository();
    _ok(await repo.create(aProject(name: 'Alpha')));
    _ok(await repo.update(aProject(name: 'Alpha Renamed')));
    final Project renamed = (await repo.watchAll().first).single;
    expect(renamed.name, 'Alpha Renamed');
    expect(renamed.folderName, 'test-project');
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
