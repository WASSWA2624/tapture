import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_photo_repository.dart';

void main() {
  late FakePhotoRepository repo;

  setUp(() {
    repo = FakePhotoRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  test('save then byId round-trips a photo', () async {
    final PhotoAsset stored = _ok(await repo.save(aPhoto(recordId: 'r1')));
    expect(_ok(await repo.byId(stored.id))?.recordId, 'r1');
  });

  test('watchByRecord lists only that record', () async {
    _ok(await repo.save(aPhoto(recordId: 'r1')));
    _ok(
      await repo.save((
        id: 'photo-2',
        projectId: 'project-1',
        recordId: 'r2',
        relativePath: 'photos/r2/a.jpg',
        sha256: 'other',
      )),
    );
    expect(await repo.watchByRecord('r1').first, hasLength(1));
    expect(await repo.watchByRecord('r2').first, hasLength(1));
  });

  test('save without a project is a ValidationFailure', () async {
    final Result<PhotoAsset> saved = await repo.save(aPhoto(projectId: ''));
    expect(_failure(saved), isA<ValidationFailure>());
    expect(_failure(saved).recoveryAction, isNotEmpty);
  });

  test('delete with an empty reason is a StorageFailure', () async {
    final PhotoAsset stored = _ok(await repo.save(aPhoto()));
    expect(
      _failure(await repo.delete(stored.id, reason: '')),
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
