import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image;
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/projects.dart' show Project;
import 'package:tapture/features/records/records.dart';

/// Seeds valid native JPEG files after duration measurements. These generated
/// photographs exercise real file decoding and thumbnails, never camera timing.
Future<String> seedDevicePhotoGrid({
  required ProviderContainer container,
  required sqlite.AppDatabase database,
  required StorageRoot root,
  required Project project,
  required String templateId,
}) async {
  final RecordEntry record =
      (await container.read(recordRepositoryProvider).save((
        projectId: project.id,
        templateId: templateId,
        fields: <String, String>{'serial': 'metric-photo-grid'},
        context: <String, String>{},
      ))).getOrThrow();
  final Uint8List jpeg = Uint8List.fromList(
    image.encodeJpg(
      image.Image(width: 256, height: 256)
        ..clear(image.ColorRgb8(90, 110, 130)),
    ),
  );
  final FileWriter writer = FileWriter(storageRoot: root);
  const SystemClock clock = SystemClock();
  final UuidV7Service ids = UuidV7Service(clock);
  for (int first = 0; first < 2000; first += 100) {
    final List<sqlite.PhotosCompanion> photos = <sqlite.PhotosCompanion>[];
    for (int index = first; index < first + 100; index++) {
      final String id = ids.newId();
      final List<int> comment = 'native-grid-$index'.codeUnits;
      final Uint8List bytes = Uint8List.fromList(<int>[
        ...jpeg.take(2),
        0xff,
        0xfe,
        (comment.length + 2) >> 8,
        (comment.length + 2) & 255,
        ...comment,
        ...jpeg.skip(2),
      ]);
      final String relative = 'photos/device-grid/$id.jpg';
      final WrittenFile file = (await writer.write(
        Stream<List<int>>.value(bytes),
        'projects/${project.folderName}/$relative',
      )).getOrThrow();
      final DateTime now = clock.nowUtc();
      photos.add(
        sqlite.PhotosCompanion.insert(
          id: Value<String>(id),
          projectId: project.id,
          recordId: Value<String>(record.id),
          captureSessionId: 'metric-grid',
          originalFilename: '$id.jpg',
          storedFilename: '$id.jpg',
          relativePath: relative,
          photoType: 'other',
          sortOrder: index,
          width: 256,
          height: 256,
          fileSize: file.byteLength,
          mimeType: 'image/jpeg',
          sha256: file.sha256,
          capturedAt: now,
          createdAt: now,
          updatedAt: now,
          updatedByDevice: 'metric-source',
          rev: const Value<int>(1),
        ),
      );
    }
    await database.batch(
      (Batch batch) => batch.insertAll(database.photos, photos),
    );
  }
  return record.id;
}
