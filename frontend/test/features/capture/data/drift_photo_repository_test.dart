import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/file_reader.dart';
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
      final StorageRoot storage = StorageRoot.fake(documentsDirectory: root);
      final DriftPhotoRepository repository = DriftPhotoRepository(
        db: db,
        writer: FileWriter(storageRoot: storage),
        reader: FileReader(storageRoot: storage),
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
        storageRoot: storage,
        decodeThumbnail:
            (
              String sourcePath, {
              required int longEdge,
              required int quality,
            }) async {
              return File(sourcePath).readAsBytes();
            },
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
      final Directory resolved = _ok(await storage.resolve());
      final File original = File(
        '${resolved.path}/projects/${project.folderName}/photos/photo-1.jpg',
      );
      expect(original.readAsBytesSync(), <int>[1, 2, 3, 4]);
      expect(_ok(await repository.readBytes(saved)), <int>[1, 2, 3, 4]);
      expect(
        _ok(await repository.cachedThumbnailPath(saved, edge: 32)),
        isNotEmpty,
      );

      final PhotoDraft derived = _ok(
        await repository.saveDraft(
          saved.copyWith(
            id: 'photo-2',
            relativePath: 'photos/photo-2.png',
            storedFilename: 'photo-2.png',
            derivedFrom: saved.id,
            rotationDegrees: 90,
            sha256: 'pending',
          ),
          bytes: Uint8List.fromList(<int>[9, 9, 9]),
        ),
      );
      expect(derived.derivedFrom, saved.id);
      expect(derived.rotationDegrees, 90);
      expect(original.readAsBytesSync(), <int>[1, 2, 3, 4]);

      _ok(await repository.retireDerived(derived.id));
      expect(await repository.readBytes(saved), isA<Success<Uint8List>>());
      final Result<void> refused = await repository.retireDerived(saved.id);
      expect(refused, isA<FailureResult<void>>());
      expect(original.readAsBytesSync(), <int>[1, 2, 3, 4]);
    },
  );

  test('session bytes still produce a thumbnail when decoding fails', () async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);
    final Directory root = await Directory.systemTemp.createTemp(
      'tapture-drift-thumb-',
    );
    addTearDown(() => root.delete(recursive: true));
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 24, 8));
    final Project project = await db.select(db.projects).getSingle();
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: root);
    final DriftPhotoRepository repository = DriftPhotoRepository(
      db: db,
      writer: FileWriter(storageRoot: storage),
      reader: FileReader(storageRoot: storage),
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
      storageRoot: storage,
      decodeThumbnail:
          (String _, {required int longEdge, required int quality}) async =>
              throw StateError('decode failed'),
    );
    final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final PhotoDraft saved = _ok(
      await repository.saveDraft(
        PhotoDraft(
          id: 'photo-1',
          projectId: project.id,
          captureSessionId: 'session-1',
          originalFilename: 'IMG_0001.JPG',
          storedFilename: 'photo-1.jpg',
          relativePath: 'photos/photo-1.jpg',
          sha256: '',
          width: 2,
          height: 2,
        ),
        bytes: bytes,
      ),
    );
    final Directory resolved = _ok(await storage.resolve());
    final File original = File(
      '${resolved.path}/projects/${project.folderName}/photos/photo-1.jpg',
    );
    final String thumb = _ok(
      await repository.cachedThumbnailForBytes(saved, bytes, edge: 32),
    );
    expect(File(thumb).existsSync(), isTrue);
    expect(original.readAsBytesSync(), <int>[1, 2, 3, 4]);
    original.deleteSync();
    expect(await repository.readBytes(saved), isA<FailureResult<Uint8List>>());
  });

  test(
    'a photo written by the blob writer reads back through the reader',
    () async {
      final AppDatabase db = await seededDatabase();
      addTearDown(db.close);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 26, 15, 50));
      final Project project = await db.select(db.projects).getSingle();
      final Map<String, Uint8List> files = <String, Uint8List>{};
      final DriftPhotoRepository repository = DriftPhotoRepository(
        db: db,
        writer: BlobFileWriter(BlobStore.memory(backing: files)),
        reader: FileReader.memory(files),
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
      );
      final PhotoDraft saved = _ok(
        await repository.saveDraft(
          PhotoDraft(
            id: 'photo-1',
            projectId: project.id,
            captureSessionId: 'session-1',
            originalFilename: 'photo-1.jpg',
            storedFilename: 'photo-1.jpg',
            relativePath: 'photos/photo-1.jpg',
            sha256: '',
          ),
          bytes: Uint8List.fromList(<int>[5, 6, 7]),
        ),
      );

      expect(files.keys, <String>[
        'projects/${project.folderName}/photos/photo-1.jpg',
      ]);
      expect(saved.fileSize, 3);
      expect(_ok(await repository.readBytes(saved)), <int>[5, 6, 7]);

      // A reload is a new writer and reader over the same stored map.
      final DriftPhotoRepository reloaded = DriftPhotoRepository(
        db: db,
        writer: BlobFileWriter(BlobStore.memory(backing: files)),
        reader: FileReader.memory(files),
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
      );
      expect(_ok(await reloaded.readBytes(saved)), <int>[5, 6, 7]);
    },
  );

  test('a photo missing from the store is a storage failure', () async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 26, 15, 50));
    final Project project = await db.select(db.projects).getSingle();
    final DriftPhotoRepository repository = DriftPhotoRepository(
      db: db,
      writer: BlobFileWriter(BlobStore.memory()),
      reader: FileReader.memory(),
      clock: clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(clock),
    );

    final Result<Uint8List> read = await repository.readBytes(
      PhotoDraft(
        id: 'photo-9',
        projectId: project.id,
        captureSessionId: 'session-1',
        originalFilename: 'photo-9.jpg',
        storedFilename: 'photo-9.jpg',
        relativePath: 'photos/photo-9.jpg',
        sha256: 'abc',
      ),
    );

    expect(read, isA<FailureResult<Uint8List>>());
    expect((read as FailureResult<Uint8List>).failure, isA<StorageFailure>());
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
