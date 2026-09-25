import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart' hide Project;
import 'package:tapture/core/db/tables/records.dart';
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

  Future<void> record(String status) async {
    _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          projectId: const Value<String>('project-1'),
          templateId: const Value<String>('template-1'),
          status: Value<String>(status),
          processingMode: const Value<String>('manual'),
          contextJson: const Value<String>('{}'),
          identityHash: Value<String>('hash-$status'),
          source: const Value<String>('capture'),
          capturedAt: Value<DateTime>(DateTime.utc(2026, 9, 24, 8)),
          capturedBy: const Value<String>('Ada'),
        ),
        clock: FixedClock(DateTime.utc(2026, 9, 24, 8)),
        deviceId: 'device-test',
        ids: UuidV7Service.sequence(FixedClock(DateTime.utc(2026, 9, 24, 8))),
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
