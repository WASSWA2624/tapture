import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/projects.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/templates.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/orphan_scanner.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/hash/hashing_service.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  test(
    'a stray file and a missing file report once each and ignore .cache',
    () async {
      final _Harness harness = await _Harness.open();
      final OrphanReport report = _ok(
        await harness.scanner.scan(harness.project.id),
      );

      expect(report.filesWithoutRows, hasLength(1));
      expect(report.rowsWithoutFiles, hasLength(1));
      expect(report.filesWithoutRows.single.path, harness.strayRelative);
      expect(report.filesWithoutRows.single.bytes, harness.strayBytes);
      expect(report.filesWithoutRows.single.kind, 'photo');
      expect(report.reclaimableBytes, harness.strayBytes);
      expect(report.rowsWithoutFiles.single.entityType, 'photos');
      expect(report.rowsWithoutFiles.single.id, harness.missing.id);
      expect(report.rowsWithoutFiles.single.expectedPath, harness.missingPath);
      expect(harness.stray.existsSync(), isTrue);
      expect(harness.cacheFile.existsSync(), isTrue);
      expect(harness.kept.existsSync(), isTrue);
      expect(File(harness.partPath).existsSync(), isTrue);
    },
  );

  test(
    'a cancelled scan returns no report and changes nothing on disk',
    () async {
      final _Harness harness = await _Harness.open();
      final int photosBefore = await harness.photoCount();
      final CancellationToken cancel = CancellationToken()..cancel();

      final Result<OrphanReport> result = await harness.scanner.scan(
        harness.project.id,
        cancel: cancel,
      );

      expect(
        result.fold((Failure failure) => failure, (_) => null),
        isA<CancelledFailure>(),
      );
      expect(harness.stray.existsSync(), isTrue);
      expect(harness.cacheFile.existsSync(), isTrue);
      expect(harness.kept.existsSync(), isTrue);
      expect(await harness.photoCount(), photosBefore);
    },
  );

  test(
    'adoption writes a hashed media row and flagging leaves evidence intact',
    () async {
      final _Harness harness = await _Harness.open();
      final OrphanReport report = _ok(
        await harness.scanner.scan(harness.project.id),
      );
      final String digest = _ok(await sha256OfFile(harness.stray));
      final Photo missingBefore = await harness.photo(harness.missing.id);

      _ok(
        await harness.scanner.adopt(
          report.filesWithoutRows.single,
          recordId: harness.record.id,
        ),
      );
      _ok(await harness.scanner.flagMissing(report.rowsWithoutFiles.single));

      final Photo adopted = await harness.photoByPath(harness.strayRelative);
      expect(adopted.sha256, digest);
      expect(adopted.recordId, harness.record.id);
      expect(adopted.projectId, harness.project.id);
      expect(adopted.relativePath, harness.strayRelative);
      expect(adopted.fileSize, harness.strayBytes);
      expect(adopted.rev, 1);
      expect(adopted.id, isNotEmpty);
      expect(adopted.updatedByDevice, harness.deviceId);
      expect(harness.stray.existsSync(), isTrue);

      final Photo missingAfter = await harness.photo(harness.missing.id);
      expect(missingAfter.sha256, missingBefore.sha256);
      expect(missingAfter.relativePath, missingBefore.relativePath);
      expect(missingAfter.fileSize, missingBefore.fileSize);
      expect(missingAfter.rev, missingBefore.rev);
      expect(harness.cacheFile.existsSync(), isTrue);

      final List<AuditLogData> flags = await harness.flagsFor(missingAfter.id);
      expect(flags, hasLength(1));
      expect(flags.single.fieldKey, 'evidenceMissing');
      expect(flags.single.newValue, 'true');

      final OrphanReport after = _ok(
        await harness.scanner.scan(harness.project.id),
      );
      expect(after.filesWithoutRows, isEmpty);
      expect(after.rowsWithoutFiles, hasLength(1));
    },
  );
}

final class _Harness {
  _Harness._({
    required this.db,
    required this.scanner,
    required this.project,
    required this.record,
    required this.missing,
    required this.stray,
    required this.kept,
    required this.cacheFile,
    required this.partPath,
    required this.strayRelative,
    required this.missingPath,
    required this.strayBytes,
    required this.deviceId,
  });

  final AppDatabase db;
  final OrphanScanner scanner;
  final Project project;
  final RecordRow record;
  final Photo missing;
  final File stray;
  final File kept;
  final File cacheFile;
  final String partPath;
  final String strayRelative;
  final String missingPath;
  final int strayBytes;
  final String deviceId;

  static const String _deviceId = 'device-a';

  static Future<_Harness> open() async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-orphan-',
    );
    addTearDown(() {
      if (documents.existsSync()) {
        documents.deleteSync(recursive: true);
      }
    });
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
    final FixedClock clock = FixedClock(t0);
    final UuidV7Service ids = UuidV7Service.sequence(clock);
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);
    final Project project = _ok(
      await upsertProject(
        db,
        row: const ProjectsCompanion(
          name: Value<String>('Inventory'),
          client: Value<String>('Acme'),
          status: Value<ProjectStatus>(ProjectStatus.active),
          folderName: Value<String>('inventory__aaaaaa'),
          settings: Value<String>('{}'),
        ),
        clock: clock,
        deviceId: _deviceId,
        ids: ids,
      ),
    );
    final Directory projectDir = _ok(
      await ProjectFolders(storageRoot: storage).create(project),
    );
    final Template template = _ok(
      await upsertTemplate(
        db,
        row: TemplatesCompanion(
          projectId: Value<String?>(project.id),
          name: const Value<String>('Medical Equipment'),
          kind: const Value<String>('equipment'),
          source: const Value<String>('shipped'),
        ),
        clock: clock,
        deviceId: _deviceId,
        ids: ids,
      ),
    );
    final RecordRow record = _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          projectId: Value<String>(project.id),
          templateId: Value<String>(template.id),
          status: const Value<String>('captured'),
          processingMode: const Value<String>('manual'),
          contextJson: const Value<String>('{}'),
          identityHash: const Value<String>('hash-1'),
          source: const Value<String>('capture'),
          capturedAt: Value<DateTime>(t0),
          capturedBy: const Value<String>('Ada'),
        ),
        clock: clock,
        deviceId: _deviceId,
        ids: ids,
      ),
    );
    const String keptRelative = 'photos/_unfiled/kept.jpg';
    const String strayRelative = 'photos/_unfiled/stray.jpg';
    const String missingPath = 'photos/_unfiled/gone.jpg';
    final File kept = File('${projectDir.path}/$keptRelative')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(const <int>[1, 2, 3, 4]);
    final File stray = File('${projectDir.path}/$strayRelative')
      ..writeAsBytesSync(const <int>[9, 8, 7, 6, 5]);
    final File cacheFile = File('${projectDir.path}/.cache/ignored.bin')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(const <int>[7, 7]);
    final String partPath = '${projectDir.path}/photos/_unfiled/tmp.jpg.part';
    File(partPath).writeAsBytesSync(const <int>[1]);
    _ok(
      await upsertPhoto(
        db,
        row: PhotosCompanion(
          projectId: Value<String>(project.id),
          recordId: Value<String?>(record.id),
          captureSessionId: const Value<String>('session-1'),
          originalFilename: const Value<String>('kept.jpg'),
          storedFilename: const Value<String>('kept.jpg'),
          relativePath: const Value<String>(keptRelative),
          photoType: const Value<String>('front'),
          sortOrder: const Value<int>(0),
          width: const Value<int>(1600),
          height: const Value<int>(1200),
          fileSize: Value<int>(kept.lengthSync()),
          mimeType: const Value<String>('image/jpeg'),
          sha256: const Value<String>('sha-kept'),
          capturedAt: Value<DateTime>(t0),
        ),
        clock: clock,
        deviceId: _deviceId,
        ids: ids,
      ),
    );
    final Photo missing = _ok(
      await upsertPhoto(
        db,
        row: PhotosCompanion(
          projectId: Value<String>(project.id),
          recordId: Value<String?>(record.id),
          captureSessionId: const Value<String>('session-1'),
          originalFilename: const Value<String>('gone.jpg'),
          storedFilename: const Value<String>('gone.jpg'),
          relativePath: const Value<String>(missingPath),
          photoType: const Value<String>('front'),
          sortOrder: const Value<int>(1),
          width: const Value<int>(1600),
          height: const Value<int>(1200),
          fileSize: const Value<int>(32),
          mimeType: const Value<String>('image/jpeg'),
          sha256: const Value<String>('sha-gone'),
          capturedAt: Value<DateTime>(t0),
        ),
        clock: clock,
        deviceId: _deviceId,
        ids: ids,
      ),
    );
    return _Harness._(
      db: db,
      scanner: OrphanScanner(
        db: db,
        storageRoot: storage,
        clock: clock,
        deviceId: _deviceId,
        ids: ids,
      ),
      project: project,
      record: record,
      missing: missing,
      stray: stray,
      kept: kept,
      cacheFile: cacheFile,
      partPath: partPath,
      strayRelative: strayRelative,
      missingPath: missingPath,
      strayBytes: stray.lengthSync(),
      deviceId: _deviceId,
    );
  }

  Future<int> photoCount() {
    return db.select(db.photos).get().then((List<Photo> rows) => rows.length);
  }

  Future<Photo> photo(String id) {
    return (db.select(
      db.photos,
    )..where(($PhotosTable tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<Photo> photoByPath(String relativePath) {
    return (db.select(db.photos)
          ..where(($PhotosTable tbl) => tbl.relativePath.equals(relativePath)))
        .getSingle();
  }

  Future<List<AuditLogData>> flagsFor(String entityId) {
    return (db.select(db.auditLog)..where(
          ($AuditLogTable tbl) =>
              tbl.entityId.equals(entityId) &
              tbl.fieldKey.equals('evidenceMissing'),
        ))
        .get();
  }
}

T _ok<T>(Result<T> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (T value) => value);
}
