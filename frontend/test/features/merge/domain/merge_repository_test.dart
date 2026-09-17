import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/merge/domain/merge_repository.dart';

import '../../../support/fakes/fake_merge_repository.dart';

void main() {
  late FakeMergeRepository repo;

  setUp(() {
    repo = FakeMergeRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  test('save then byId round-trips a merge session', () async {
    const MergeSession session = (
      id: 'merge-1',
      bundleName: 'site.zip',
      status: 'preview',
    );
    _ok(await repo.save(session));
    expect(_ok(await repo.byId('merge-1'))?.bundleName, 'site.zip');
    expect(await repo.watchAll().first, hasLength(1));
  });

  test('save without a bundle name is a ValidationFailure', () async {
    const MergeSession session = (
      id: 'merge-1',
      bundleName: '',
      status: 'preview',
    );
    expect(_failure(await repo.save(session)), isA<ValidationFailure>());
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
