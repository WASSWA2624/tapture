import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/import/pdf_pages.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/capture_document_repository_impl.dart';
import 'package:tapture/features/capture/data/drift_photo_repository.dart';
import 'package:tapture/features/projects/data/project_repository_impl.dart';
import 'package:tapture/features/projects/domain/project_status.dart' as domain;
import 'package:tapture/features/records/data/record_repository_impl.dart';

import '../../../core/db/record_rows.dart';
import 'record_read_seeds.dart' show seedProjectRow, seedTemplateRow, seedTomb;

void main() {
  late AppDatabase db;
  late ProjectRepositoryImpl projects;
  late DriftPhotoRepository photos;
  late CaptureDocumentRepositoryImpl attachments;
  late RecordRepositoryImpl records;
  late Map<String, Uint8List> files;
  final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 7));
  int recoveredTrees = 0;
  Failure? restoreFailure;

  setUp(() async {
    db = AppDatabase.memory();
    files = <String, Uint8List>{};
    recoveredTrees = 0;
    restoreFailure = null;
    final IdService ids = UuidV7Service.sequence(clock);
    final BlobFileWriter writer = BlobFileWriter(BlobStore.memory(backing: files));
    final FileReader reader = FileReader.memory(files);
    projects = ProjectRepositoryImpl(db: db, clock: clock, deviceId: 'test', ids: ids,
      recycleTree: ({required String id, required String name, required String folderName}) async => const Success<void>(null),
      restoreTree: ({required String id, required String name, required String folderName}) async {
        recoveredTrees += 1;
        return restoreFailure == null ? const Success<void>(null) : FailureResult<void>(restoreFailure!);
      },
    );
    photos = DriftPhotoRepository(db: db, writer: writer, reader: reader, clock: clock, deviceId: 'test', ids: ids);
    attachments = CaptureDocumentRepositoryImpl(db: db, writer: writer, reader: reader, pages: PdfPages.fake(), clock: clock, deviceId: 'test', ids: ids);
    records = RecordRepositoryImpl(db: db, clock: clock, deviceId: 'test', ids: ids);
    await seedProjectRow(db, 'p1', folder: 'field');
    await seedTemplateRow(db, 't1');
    await seedRecord(db, 'r1');
    await seedRecord(db, 'r2');
    await seedPhoto(db, 'photo', recordId: 'r1');
    files['projects/field/photos/photo.jpg'] = Uint8List.fromList(<int>[1, 2, 3, 4]);
    for (final String kind in <String>['document', 'audio']) {
      await seedRow(db, 'attachments', <String, Object?>{
        'id': kind, 'project_id': 'p1', 'relative_path': '$kind/source.bin',
        'mime_type': 'application/octet-stream', 'file_size': 4, 'sha256': 'hash-$kind', 'kind': kind,
      });
      files['projects/field/$kind/source.bin'] = Uint8List.fromList(<int>[4, 3, 2, 1]);
    }
  });
  tearDown(() => db.close());

  test('all managed kinds are projected, restored, audited and byte-identical', () async {
    await seedTomb(db, 'photos', 'photo');
    await seedTomb(db, 'attachments', 'document');
    await seedTomb(db, 'attachments', 'audio');
    final Map<String, String> before = files.map((String key, Uint8List bytes) => MapEntry<String, String>(key, sha256.convert(bytes).toString()));
    expect((await photos.watchDeleted().first).single.kind, DeletedEntityKind.photo);
    expect((await attachments.watchDeleted().first).map((DeletedEntity row) => row.kind), containsAll(<DeletedEntityKind>[DeletedEntityKind.audio, DeletedEntityKind.document]));
    (await photos.restore('photo')).getOrThrow();
    (await attachments.restore('document')).getOrThrow();
    (await attachments.restore('audio')).getOrThrow();
    expect(await photos.watchDeleted().first, isEmpty);
    expect(await attachments.watchDeleted().first, isEmpty);
    expect((await db.select(db.photos).getSingle()).rev, 2);
    expect((await db.select(db.auditLog).get()).where((AuditLogData row) => row.fieldKey == 'restored'), hasLength(3));
    expect(files.map((String key, Uint8List bytes) => MapEntry<String, String>(key, sha256.convert(bytes).toString())), before);
    (await photos.restore('photo')).getOrThrow();
    (await attachments.restore('audio')).getOrThrow();
    expect((await db.select(db.auditLog).get()).where((AuditLogData row) => row.fieldKey == 'restored'), hasLength(3));
  });

  test('a deleted record suppresses children and refuses child restoration', () async {
    await seedRow(db, 'attachment_owners', <String, Object?>{'id': 'owner', 'attachment_id': 'audio', 'owner_type': 'record', 'owner_id': 'r1'});
    await seedTomb(db, 'photos', 'photo');
    await seedTomb(db, 'attachments', 'audio');
    (await records.delete('r1', reason: 'independent')).getOrThrow();
    expect(await photos.watchDeleted().first, isEmpty);
    expect(await attachments.watchDeleted().first, isEmpty);
    expect(await photos.restore('photo'), isA<FailureResult<void>>());
    expect(await attachments.restore('audio'), isA<FailureResult<void>>());
    (await records.restore('r1')).getOrThrow();
    expect((await photos.watchDeleted().first).single.id, 'photo');
    expect((await attachments.watchDeleted().first).single.id, 'audio');
  });

  test('shared attachment restoration retains independent owner tombstones', () async {
    for (final String record in <String>['r1', 'r2']) {
      await seedRow(db, 'attachment_owners', <String, Object?>{'id': 'owner-$record', 'attachment_id': 'audio', 'owner_type': 'record', 'owner_id': record});
    }
    await seedTomb(db, 'attachments', 'audio');
    await seedTomb(db, 'attachment_owners', 'owner-r1');
    (await records.delete('r1', reason: 'independent')).getOrThrow();
    expect((await attachments.watchDeleted().first).single.id, 'audio');
    (await attachments.restore('audio')).getOrThrow();
    expect((await db.select(db.tombstones).get()).map((Tombstone row) => row.entityId), contains('owner-r1'));
    expect(await db.select(db.attachmentOwners).get(), hasLength(2));
  });

  test('project restoration retains independent deletions and previous status', () async {
    (await projects.setStatus('p1', domain.ProjectStatus.archived)).getOrThrow();
    await seedCaption(db, 'caption', ownerType: 'photo', ownerId: 'photo', text: 'raw original');
    await seedTomb(db, 'captions', 'caption', reason: 'independent caption');
    await seedTomb(db, 'photos', 'photo', reason: 'independent photo');
    (await records.delete('r2', reason: 'independent record')).getOrThrow();
    (await projects.delete('p1')).getOrThrow();
    expect((await projects.watchDeleted().first).single.kind, DeletedEntityKind.project);
    expect(await records.watchBin().first, isEmpty);
    expect(await photos.watchDeleted().first, isEmpty);
    expect(await attachments.watchDeleted().first, isEmpty);
    expect(await records.restore('r2'), isA<FailureResult<void>>());
    expect(await attachments.restore('audio'), isA<FailureResult<void>>());
    (await projects.restore('p1')).getOrThrow();
    expect(recoveredTrees, 1);
    expect((await projects.watchAll(includeArchived: true).first).single.status, domain.ProjectStatus.archived);
    expect((await db.select(db.tombstones).get()).map((Tombstone row) => row.entityId).toSet(), <String>{'photo', 'caption', 'r2'});
    expect((await db.select(db.captions).getSingle()).textRaw, 'raw original');
    expect((await records.watchBin().first).single.id, 'r2');
    expect((await photos.watchDeleted().first).single.id, 'photo');
    expect(await attachments.watchDeleted().first, isEmpty);
    (await projects.restore('p1')).getOrThrow();
    expect(recoveredTrees, 1);
  });

  test('storage failure keeps the project and all cascade tombstones deleted', () async {
    (await projects.delete('p1')).getOrThrow();
    final int count = (await db.select(db.tombstones).get()).length;
    restoreFailure = const StorageFailure(message: 'Collision', recoveryAction: 'Move the conflicting folder.');
    expect(await projects.restore('p1'), isA<FailureResult<void>>());
    expect((await db.select(db.tombstones).get()).length, count);
    expect(await projects.watchAll().first, isEmpty);
  });

  test('interrupted database restoration retries after storage has moved', () async {
    (await projects.delete('p1')).getOrThrow();
    final int count = (await db.select(db.tombstones).get()).length;
    await db.customStatement("CREATE TRIGGER refuse_restore BEFORE DELETE ON tombstones WHEN OLD.entity_type = 'projects' BEGIN SELECT RAISE(ABORT, 'injected failure'); END");
    expect(await projects.restore('p1'), isA<FailureResult<void>>());
    expect((await db.select(db.tombstones).get()).length, count);
    expect(await projects.watchAll().first, isEmpty);
    await db.customStatement('DROP TRIGGER refuse_restore');
    (await projects.restore('p1')).getOrThrow();
    expect(recoveredTrees, 2);
    expect(await projects.watchDeleted().first, isEmpty);
    expect((await projects.watchAll().first).single.status, domain.ProjectStatus.active);
  });

  test('legacy project deletion without an audit restores as active', () async {
    await db.customStatement("UPDATE projects SET status = 'deleted' WHERE id = 'p1'");
    await seedTomb(db, 'projects', 'p1', reason: 'Project deleted');
    (await projects.restore('p1')).getOrThrow();
    expect((await projects.watchAll().first).single.status, domain.ProjectStatus.active);
  });

  test('missing bytes leave file tombstones and revision unchanged', () async {
    await seedTomb(db, 'photos', 'photo');
    files.clear();
    expect(await photos.restore('photo'), isA<FailureResult<void>>());
    expect((await photos.watchDeleted().first).single.id, 'photo');
    expect((await db.select(db.photos).getSingle()).rev, 1);
  });

  test('failed file transaction preserves its tombstone and audit', () async {
    await seedTomb(db, 'attachments', 'document');
    await db.customStatement("CREATE TRIGGER refuse_file_restore BEFORE DELETE ON tombstones WHEN OLD.entity_id = 'document' BEGIN SELECT RAISE(ABORT, 'injected failure'); END");
    expect(await attachments.restore('document'), isA<FailureResult<void>>());
    expect((await attachments.watchDeleted().first).single.id, 'document');
    expect(await db.select(db.auditLog).get(), isEmpty);
  });

  test('watched photo bin emits after durable recovery', () async {
    await seedTomb(db, 'photos', 'photo');
    final Completer<void> first = Completer<void>();
    final Completer<void> restored = Completer<void>();
    final StreamSubscription<List<DeletedEntity>> subscription = photos.watchDeleted().listen((List<DeletedEntity> rows) {
      if (rows.isNotEmpty && !first.isCompleted) first.complete();
      if (rows.isEmpty && first.isCompleted && !restored.isCompleted) restored.complete();
    });
    addTearDown(subscription.cancel);
    await first.future;
    (await photos.restore('photo')).getOrThrow();
    await restored.future;
  });

  test('repeated photo deletion retains the original tombstone', () async {
    (await photos.delete('photo', reason: 'original reason')).getOrThrow();
    final Tombstone before = await db.select(db.tombstones).getSingle();
    (await photos.delete('photo', reason: 'later reason')).getOrThrow();
    final Tombstone after = await db.select(db.tombstones).getSingle();
    expect(after, before);
  });
}
