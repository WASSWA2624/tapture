@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/files/blob_file_reader.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/import/pdf_pages.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/capture_document_repository_impl.dart';
import 'package:tapture/features/capture/data/drift_photo_repository.dart';
import 'package:tapture/features/projects/data/project_repository_impl.dart';

import '../../../core/db/record_rows.dart';
import 'record_read_seeds.dart';

void main() {
  test(
    'WASM rows and IndexedDB evidence survive project and file recovery',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      final String storeName =
          'recycle-${DateTime.now().microsecondsSinceEpoch}';
      final BlobStore store = BlobStore.platform(storeName);
      final BlobFileWriter writer = BlobFileWriter(store);
      final BlobFileReader reader = BlobFileReader(store);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 8));
      final IdService ids = UuidV7Service.sequence(clock);
      final ProjectRepositoryImpl projects = ProjectRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'browser',
        ids: ids,
      );
      final DriftPhotoRepository photos = DriftPhotoRepository(
        db: db,
        writer: writer,
        reader: reader,
        clock: clock,
        deviceId: 'browser',
        ids: ids,
      );
      final CaptureDocumentRepositoryImpl attachments =
          CaptureDocumentRepositoryImpl(
            db: db,
            writer: writer,
            reader: reader,
            pages: PdfPages.fake(),
            clock: clock,
            deviceId: 'browser',
            ids: ids,
          );
      await seedProjectRow(db, 'p1', folder: 'field');
      await seedTemplateRow(db, 't1');
      await seedRecord(db, 'r1');
      await seedPhoto(db, 'photo', recordId: 'r1');
      final Map<String, Uint8List> originals = <String, Uint8List>{
        'photos/photo.jpg': Uint8List.fromList(<int>[1, 2, 3, 4]),
        'documents/source.bin': Uint8List.fromList(<int>[5, 6, 7, 8]),
        'audio/source.bin': Uint8List.fromList(<int>[9, 10, 11, 12]),
      };
      for (final MapEntry<String, Uint8List> entry in originals.entries) {
        final String path = 'projects/field/${entry.key}';
        (await writer.write(
          Stream<List<int>>.value(entry.value),
          path,
        )).getOrThrow();
        addTearDown(() async => (await store.remove(path)).getOrThrow());
      }
      for (final String kind in <String>['document', 'audio']) {
        await seedRow(db, 'attachments', <String, Object?>{
          'id': kind,
          'project_id': 'p1',
          'relative_path':
              '${kind == 'document' ? 'documents' : kind}/source.bin',
          'mime_type': 'application/octet-stream',
          'file_size': 4,
          'sha256': 'hash-$kind',
          'kind': kind,
        });
        await seedTomb(
          db,
          'attachments',
          kind,
          reason: 'Independent file deletion',
        );
      }
      (await photos.delete(
        'photo',
        reason: 'Independent photo deletion',
      )).getOrThrow();
      (await projects.delete('p1')).getOrThrow();
      expect((await projects.watchDeleted().first).single.id, 'p1');
      expect(await photos.watchDeleted().first, isEmpty);
      expect(await attachments.watchDeleted().first, isEmpty);
      (await projects.restore('p1')).getOrThrow();
      expect((await photos.watchDeleted().first).single.id, 'photo');
      expect(
        (await attachments.watchDeleted().first).map((row) => row.kind),
        containsAll(<DeletedEntityKind>[
          DeletedEntityKind.audio,
          DeletedEntityKind.document,
        ]),
      );
      (await photos.restore('photo')).getOrThrow();
      (await attachments.restore('document')).getOrThrow();
      (await attachments.restore('audio')).getOrThrow();
      final BlobFileReader reopened = BlobFileReader(
        BlobStore.platform(storeName),
      );
      for (final MapEntry<String, Uint8List> entry in originals.entries) {
        final Uint8List read = (await reopened.read(
          'projects/field/${entry.key}',
        )).getOrThrow();
        expect(sha256.convert(read), sha256.convert(entry.value));
      }
      expect(await db.select(db.tombstones).get(), isEmpty);
      expect(await photos.watchDeleted().first, isEmpty);
      expect(await attachments.watchDeleted().first, isEmpty);
      expect(
        (await db.select(db.auditLog).get()).where(
          (row) => row.fieldKey == 'restored',
        ),
        hasLength(5),
      );
    },
  );
}
