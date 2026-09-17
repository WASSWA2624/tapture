import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';

import '../../../support/fakes/fake_export_repository.dart';

void main() {
  late FakeExportRepository repo;

  setUp(() {
    repo = FakeExportRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  test('save then byId round-trips an export', () async {
    const ExportEntry entry = (
      id: 'ex-1',
      projectId: 'project-1',
      version: 1,
      status: 'complete',
    );
    _ok(await repo.save(entry));
    expect(_ok(await repo.byId('ex-1'))?.version, 1);
    expect(await repo.watchByProject('project-1').first, hasLength(1));
    expect(await repo.watchByProject('other').first, isEmpty);
  });

  test('save without a project is a ValidationFailure', () async {
    const ExportEntry entry = (
      id: 'ex-1',
      projectId: '',
      version: 1,
      status: 'complete',
    );
    expect(_failure(await repo.save(entry)), isA<ValidationFailure>());
  });

  test('delete with an empty reason is a StorageFailure', () async {
    _ok(
      await repo.save((
        id: 'ex-1',
        projectId: 'project-1',
        version: 1,
        status: 'complete',
      )),
    );
    expect(
      _failure(await repo.delete('ex-1', reason: '')),
      isA<StorageFailure>(),
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
