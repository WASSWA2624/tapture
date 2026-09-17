import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/records/domain/record_repository.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_record_repository.dart';

void main() {
  late FakeRecordRepository repo;

  setUp(() {
    repo = FakeRecordRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  test('save then byId round-trips a record', () async {
    final RecordDetail stored = _ok(
      await repo.save(aRecord(fields: const <String, String>{'serial': 'Z-9'})),
    );
    expect(stored.status, 'captured');
    expect(_ok(await repo.byId(stored.id))?.fields['serial'], 'Z-9');
  });

  test('watchByProject honours the status filter', () async {
    _ok(await repo.save(aRecord()));
    final List<RecordSummary> all = await repo.watchByProject('project-1', (
      status: null,
    )).first;
    expect(all, hasLength(1));
    expect(
      await repo.watchByProject('project-1', (status: 'approved')).first,
      isEmpty,
    );
    expect(await repo.watchByProject('other', (status: null)).first, isEmpty);
  });

  test('save without a project is a ValidationFailure', () async {
    final Result<RecordDetail> saved = await repo.save(aRecord(projectId: ''));
    expect(_failure(saved), isA<ValidationFailure>());
    expect(_failure(saved).recoveryAction, isNotEmpty);
  });

  test('delete with an empty reason is a StorageFailure', () async {
    final RecordDetail stored = _ok(await repo.save(aRecord()));
    final Result<void> deleted = await repo.delete(stored.id, reason: '');
    expect(_failure(deleted), isA<StorageFailure>());
    expect(_ok(await repo.byId(stored.id)), isNotNull);
  });

  test('delete removes the row from watch and byId', () async {
    final RecordDetail stored = _ok(await repo.save(aRecord()));
    _ok(await repo.delete(stored.id, reason: 'duplicate'));
    expect(_ok(await repo.byId(stored.id)), isNull);
    expect(
      await repo.watchByProject('project-1', (status: null)).first,
      isEmpty,
    );
  });

  test('byId of a missing row is Success(null), not a throw', () async {
    expect(_ok(await repo.byId('missing')), isNull);
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
