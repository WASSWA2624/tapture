import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/domain/processing_repository.dart';

import '../../../support/fakes/fake_processing_repository.dart';

void main() {
  late FakeProcessingRepository repo;

  setUp(() {
    repo = FakeProcessingRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  test('save then byId round-trips a job', () async {
    const ProcessingJob job = (
      id: 'job-1',
      recordId: 'record-1',
      stage: 'prepare',
      attemptCount: 0,
    );
    _ok(await repo.save(job));
    expect(_ok(await repo.byId('job-1'))?.stage, 'prepare');
    expect(await repo.watchAll().first, hasLength(1));
  });

  test('save without a record is a ValidationFailure', () async {
    const ProcessingJob job = (
      id: 'job-1',
      recordId: '',
      stage: 'prepare',
      attemptCount: 0,
    );
    expect(_failure(await repo.save(job)), isA<ValidationFailure>());
  });

  test('delete of a missing id is a StorageFailure', () async {
    expect(
      _failure(await repo.delete('missing', reason: 'gone')),
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
