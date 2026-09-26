import 'dart:convert';

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

  test('a record edit is stored beside the project new capture', () async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final CapturePersistenceImpl persistence = CapturePersistenceImpl(
      photos: photos,
      store: TextStore.memory(),
    );
    const CaptureSession fresh = CaptureSession(
      id: 'session-1',
      projectId: 'project-1',
      templateId: 'template-1',
      contextSnapshot: <String, String>{},
      captions: <String, String>{'': 'New capture'},
    );
    const CaptureSession edit = CaptureSession(
      id: 'record-1',
      projectId: 'project-1',
      templateId: 'template-1',
      contextSnapshot: <String, String>{},
      recordId: 'record-1',
      editing: true,
      captions: <String, String>{'': 'Edited'},
    );

    _ok(await persistence.saveSession(fresh));
    _ok(await persistence.saveSession(edit));
    expect(
      _ok(await persistence.loadSession('project-1'))?.recordCaption,
      'New capture',
    );
    expect(
      _ok(await persistence.loadSession('edit:record-1'))?.recordCaption,
      'Edited',
    );

    _ok(await persistence.clearSession('edit:record-1'));
    expect(_ok(await persistence.loadSession('edit:record-1')), isNull);
    expect(
      _ok(await persistence.loadSession('project-1'))?.recordCaption,
      'New capture',
    );
  });

  test('a session stored before keys is read under its project', () async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final TextStore store = TextStore.memory();
    const CaptureSession legacy = CaptureSession(
      id: 'session-1',
      projectId: 'project-1',
      templateId: 'template-1',
      contextSnapshot: <String, String>{},
      captions: <String, String>{'': 'Kept'},
    );
    await store.write(jsonEncode(legacy.toJson()));
    final CapturePersistenceImpl persistence = CapturePersistenceImpl(
      photos: photos,
      store: store,
    );

    expect(
      _ok(await persistence.loadSession('project-1'))?.recordCaption,
      'Kept',
    );
    expect(_ok(await persistence.loadSession('project-2')), isNull);
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
