import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/drift_photo_repository.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

import '../../../support/factories.dart';

void main() {
  test(
    'original bytes are durable before complete metadata is visible',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final Directory root = await Directory.systemTemp.createTemp(
        'tapture-drift-photo-',
      );
      addTearDown(() => root.delete(recursive: true));
      final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 23, 16, 35));
      final Project project = await db.select(db.projects).getSingle();
      final DriftPhotoRepository repository = DriftPhotoRepository(
        db: db,
        writer: FileWriter(
          storageRoot: StorageRoot.fake(documentsDirectory: root),
        ),
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
      );
      final PhotoDraft draft = PhotoDraft(
        id: 'photo-1',
        projectId: project.id,
        captureSessionId: 'session-1',
        originalFilename: 'IMG_0001.JPG',
        storedFilename: 'photo-1.jpg',
        relativePath: 'photos/photo-1.jpg',
        sha256: '',
        width: 2,
        height: 2,
      );

      final PhotoDraft saved = _ok(
        await repository.saveDraft(
          draft,
          bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        ),
      );

      expect(saved.sha256, isNotEmpty);
      expect(saved.fileSize, 4);
      expect((await db.select(db.photos).getSingle()).sha256, saved.sha256);
      final Directory storage = _ok(
        await StorageRoot.fake(documentsDirectory: root).resolve(),
      );
      expect(
        File(
          '${storage.path}/projects/${project.folderName}/photos/photo-1.jpg',
        ).readAsBytesSync(),
        <int>[1, 2, 3, 4],
      );
    },
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
