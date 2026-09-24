import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/drift_capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_session.dart'
    as capture;
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';

import '../../../support/factories.dart';

void main() {
  test('a project session round-trips through Drift and clears', () async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 23, 16, 35));
    final Project project = await db.select(db.projects).getSingle();
    final DriftCapturePersistence persistence = DriftCapturePersistence(
      db: db,
      photos: _CapturePhotos(),
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
    );
    final capture.CaptureSession session = capture.CaptureSession(
      id: 'session-1',
      projectId: project.id,
      templateId: 'template-1',
      contextSnapshot: const <String, String>{'country': 'Uganda'},
      isDirty: true,
    );

    _ok(await persistence.saveSession(session));
    final capture.CaptureSession? restored = _ok(
      await persistence.loadSession(project.id),
    );
    expect(restored?.toJson(), session.toJson());

    _ok(await persistence.clearSession(project.id));
    expect(_ok(await persistence.loadSession(project.id)), isNull);
  });
}

final class _CapturePhotos implements CapturePhotoRepository {
  @override
  Future<Result<PhotoDraft>> saveDraft(
    PhotoDraft photo, {
    Uint8List? bytes,
  }) async => Success<PhotoDraft>(photo);

  @override
  Future<Result<PhotoAsset?>> byId(String id) async =>
      const Success<PhotoAsset?>(null);

  @override
  Future<Result<void>> delete(String id, {required String reason}) async =>
      const Success<void>(null);

  @override
  Future<Result<PhotoAsset>> save(PhotoAsset photo) async =>
      Success<PhotoAsset>(photo);

  @override
  Stream<List<PhotoAsset>> watchByRecord(String recordId) =>
      Stream<List<PhotoAsset>>.value(const <PhotoAsset>[]);
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
