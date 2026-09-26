import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart' hide Project;
import 'package:tapture/core/db/tables/attachment_owners.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/templates.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/exports/data/export_repository_impl.dart';
import 'package:tapture/features/exports/domain/export_file_name.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';
import 'package:tapture/features/projects/data/project_repository_impl.dart';
import 'package:tapture/features/projects/domain/project.dart';

import '../../../support/factories.dart';

void main() {
  test('a second export keeps the earlier file and row', () async {
    final _Harness harness = await _Harness.open();
    addTearDown(harness.close);
    await harness.record('captured');

    final ExportedWorkbook first = _ok(
      await harness.repo.exportProject(
        'project-1',
        cancel: CancellationToken(),
      ),
    );
    final ExportedWorkbook second = _ok(
      await harness.repo.exportProject(
        'project-1',
        cancel: CancellationToken(),
      ),
    );

    expect(first.version, 1);
    expect(second.version, 2);
    final DateTime local = DateTime.utc(2026, 9, 24, 8).toLocal();
    final String display = ExportFileName.build(
      projectName: 'Test project',
      local: local,
    );
    expect(first.fileName, display);
    expect(second.fileName, display);
    final List<ExportRow> stored = await harness.db
        .select(harness.db.exports)
        .get();
    expect(stored, hasLength(2));
    expect(stored[0].filePath, isNot(stored[1].filePath));
    for (final ExportRow row in stored) {
      final String storedName = row.filePath.split('/').last;
      expect(storedName, isNot(display));
      expect(harness.file(storedName).existsSync(), isTrue);
    }
  });

  test('a display name keeps letters and digits and stamps the local time', () {
    expect(
      ExportFileName.build(
        projectName: 'Boiler / A',
        local: DateTime(2026, 9, 24, 20, 42, 13),
      ),
      'Boiler-A-240926-204213.xlsx',
    );
    expect(
      ExportFileName.build(
        projectName: '///',
        local: DateTime(2026, 1, 2, 3, 4, 5),
      ),
      'Project-020126-030405.xlsx',
    );
  });

  test('a refused write leaves records and exports unchanged', () async {
    final _Harness harness = await _Harness.open(
      writer: (StorageRoot storage) =>
          FileWriter(storageRoot: storage, permissionDenied: true),
    );
    addTearDown(harness.close);
    await harness.record('captured');

    final Result<ExportedWorkbook> written = await harness.repo.exportProject(
      'project-1',
      cancel: CancellationToken(),
    );

    expect(written, isA<FailureResult<ExportedWorkbook>>());
    expect(await harness.db.select(harness.db.exports).get(), isEmpty);
    expect(await harness.db.select(harness.db.records).get(), hasLength(1));
    expect(harness.exportDir.existsSync(), isFalse);
  });

  test('the summary counts what the workbook writes', () async {
    final _Harness harness = await _Harness.open();
    addTearDown(harness.close);
    final AppDatabase db = harness.db;
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 24, 8));
    final IdService ids = UuidV7Service.sequence(clock);
    for (final String kind in <String>['assets', 'rooms']) {
      _ok(
        await upsertTemplate(
          db,
          row: TemplatesCompanion(
            id: Value<String>(kind),
            projectId: const Value<String?>('project-1'),
            name: Value<String>(kind == 'assets' ? 'Assets' : 'Rooms'),
            kind: const Value<String>('generic'),
            source: const Value<String>('built'),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: ids,
        ),
      );
    }
    await harness.record('captured', id: 'r1', templateId: 'assets');
    await harness.record('approved', id: 'r2', templateId: 'assets');
    await harness.record(
      'archived',
      id: 'r3',
      templateId: 'rooms',
      at: DateTime.utc(2026, 9, 25, 16),
    );
    await harness.record('deleted', id: 'r4', templateId: 'rooms');
    await harness.photo('p1', recordId: 'r1');
    await harness.photo('p2', recordId: 'r2');
    await harness.photo('gone', recordId: 'r2');
    await harness.photo('p4', recordId: 'r4');
    await writeTombstone(
      db,
      entityType: 'photos',
      entityId: 'gone',
      reason: 'operator-delete',
      clock: clock,
      deviceId: 'device-test',
    );
    _ok(
      await upsertAttachment(
        db,
        row: const AttachmentsCompanion(
          id: Value<String>('clip-1'),
          projectId: Value<String>('project-1'),
          relativePath: Value<String>('audio/clip-1.wav'),
          mimeType: Value<String>('audio/wav'),
          fileSize: Value<int>(4),
          sha256: Value<String>('clip-sha'),
          kind: Value<AttachmentKind>(AttachmentKind.audio),
        ),
        clock: clock,
        deviceId: 'device-test',
        ids: ids,
      ),
    );
    await db
        .into(db.attachmentOwners)
        .insert(
          AttachmentOwnersCompanion(
            id: const Value<String>('owner-1'),
            attachmentId: const Value<String>('clip-1'),
            ownerType: const Value<AttachmentOwnerType>(
              AttachmentOwnerType.record,
            ),
            ownerId: const Value<String>('r1'),
            sortOrder: const Value<int>(0),
            createdAt: Value<DateTime>(clock.nowUtc()),
            updatedAt: Value<DateTime>(clock.nowUtc()),
            updatedByDevice: const Value<String>('device-test'),
            rev: const Value<int>(1),
          ),
        );

    final ExportSummary summary = await harness.repo
        .watchSummary('project-1')
        .first;

    expect(summary.projectName, 'Test project');
    expect(summary.records, 3);
    expect(summary.photos, 2);
    expect(summary.audioClips, 1);
    expect(summary.unprocessed, 1);
    expect(summary.needsReview, 0);
    expect(summary.approved, 1);
    expect(summary.templates, <ExportTemplateCount>[
      (name: 'Assets', records: 2),
      (name: 'Rooms', records: 1),
    ]);
    expect(summary.firstCapturedAt?.toUtc(), DateTime.utc(2026, 9, 24, 8));
    expect(summary.lastCapturedAt?.toUtc(), DateTime.utc(2026, 9, 25, 16));
  });

  test('cancellation deletes a partial file and writes no row', () async {
    final CancellationToken cancel = CancellationToken();
    final _Harness harness = await _Harness.open(
      writer: (StorageRoot storage) =>
          _CancelOnWrite(FileWriter(storageRoot: storage), cancel),
    );
    addTearDown(harness.close);
    await harness.record('captured');

    final Result<ExportedWorkbook> written = await harness.repo.exportProject(
      'project-1',
      cancel: cancel,
    );

    expect(written, isA<FailureResult<ExportedWorkbook>>());
    expect(
      (written as FailureResult<ExportedWorkbook>).failure,
      isA<CancelledFailure>(),
    );
    expect(await harness.db.select(harness.db.exports).get(), isEmpty);
    expect(
      harness.exportDir.existsSync()
          ? harness.exportDir.listSync()
          : <FileSystemEntity>[],
      isEmpty,
    );
  });
}

final class _Harness {
  _Harness({
    required this.db,
    required this.repo,
    required this.root,
    required this.folderName,
  });

  final AppDatabase db;
  final ExportRepositoryImpl repo;
  final Directory root;
  final String folderName;

  static Future<_Harness> open({
    FileWriter Function(StorageRoot storage)? writer,
  }) async {
    final AppDatabase db = AppDatabase.memory();
    final Directory documents = await Directory.systemTemp.createTemp(
      'tapture-export-',
    );
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 24, 8));
    final ProjectRepositoryImpl projects = ProjectRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
    );
    final Project created = _ok(await projects.create(aProject()));
    final Directory root = _ok(await storage.resolve());
    return _Harness(
      db: db,
      root: root,
      folderName: created.folderName,
      repo: ExportRepositoryImpl(
        db: db,
        storageRoot: storage,
        clock: clock,
        deviceId: 'device-test',
        ids: UuidV7Service.sequence(clock),
        writer: writer?.call(storage),
      ),
    );
  }

  Directory get exportDir =>
      Directory('${root.path}/projects/$folderName/exports');

  File file(String name) => File('${exportDir.path}/$name');

  Future<void> record(
    String status, {
    String? id,
    String templateId = 'template-1',
    DateTime? at,
  }) async {
    _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          id: id == null ? const Value<String>.absent() : Value<String>(id),
          projectId: const Value<String>('project-1'),
          templateId: Value<String>(templateId),
          status: Value<String>(status),
          processingMode: const Value<String>('manual'),
          contextJson: const Value<String>('{}'),
          identityHash: Value<String>('hash-${id ?? status}'),
          source: const Value<String>('capture'),
          capturedAt: Value<DateTime>(at ?? DateTime.utc(2026, 9, 24, 8)),
          capturedBy: const Value<String>('Ada'),
        ),
        clock: FixedClock(DateTime.utc(2026, 9, 24, 8)),
        deviceId: 'device-test',
        ids: UuidV7Service.sequence(FixedClock(DateTime.utc(2026, 9, 24, 8))),
      ),
    );
  }

  Future<void> photo(String id, {required String recordId}) async {
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 24, 8));
    _ok(
      await upsertPhoto(
        db,
        row: PhotosCompanion(
          id: Value<String>(id),
          projectId: const Value<String>('project-1'),
          recordId: Value<String?>(recordId),
          captureSessionId: const Value<String>('session-1'),
          originalFilename: Value<String>('$id.jpg'),
          storedFilename: Value<String>('$id.jpg'),
          relativePath: Value<String>('photos/$id.jpg'),
          photoType: const Value<String>('other'),
          sortOrder: const Value<int>(0),
          width: const Value<int>(1),
          height: const Value<int>(1),
          fileSize: const Value<int>(1),
          mimeType: const Value<String>('image/jpeg'),
          sha256: Value<String>('sha-$id'),
          capturedAt: Value<DateTime>(clock.nowUtc()),
        ),
        clock: clock,
        deviceId: 'device-test',
        ids: UuidV7Service.sequence(clock),
      ),
    );
  }

  Future<void> close() async {
    await db.close();
    final Directory documents = root.parent;
    if (documents.existsSync()) {
      documents.deleteSync(recursive: true);
    }
  }
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

final class _CancelOnWrite implements FileWriter {
  _CancelOnWrite(this._inner, this._cancel);

  final FileWriter _inner;
  final CancellationToken _cancel;

  @override
  Future<Result<WrittenFile>> write(
    Stream<List<int>> bytes,
    String relativePath,
  ) async {
    final Result<WrittenFile> written = await _inner.write(bytes, relativePath);
    _cancel.cancel();
    return written;
  }

  @override
  Future<Result<WrittenFile>> copyIn(File source, String relativePath) {
    return _inner.copyIn(source, relativePath);
  }
}
