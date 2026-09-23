import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';

import '../../../support/fakes/fake_photo_repository.dart';

void main() {
  test('memory recovery session round-trips and clears', () async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final CapturePersistenceImpl persistence = CapturePersistenceImpl(
      photos: photos,
      store: TextStore.memory(),
    );
    const CaptureSession session = CaptureSession(
      id: 'session-1',
      projectId: 'project-1',
      templateId: 'template-1',
      contextSnapshot: <String, String>{'country': 'Uganda'},
      isDirty: true,
    );

    _ok(await persistence.saveSession(session));
    expect(
      _ok(await persistence.loadSession(session.projectId))?.toJson(),
      session.toJson(),
    );

    _ok(await persistence.clearSession(session.projectId));
    expect(_ok(await persistence.loadSession(session.projectId)), isNull);
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
