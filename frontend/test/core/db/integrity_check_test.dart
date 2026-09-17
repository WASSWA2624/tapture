import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/integrity_check.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/processing.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  group('an in-memory database', () {
    late AppDatabase db;
    late UuidV7Service ids;

    setUp(() {
      db = AppDatabase.memory();
      ids = UuidV7Service.sequence(FixedClock(t0));
    });

    tearDown(() async {
      await db.close();
    });

    test('a clean database produces no findings', () async {
      final List<IntegrityFinding> findings = _ok(await runIntegrityCheck(db));
      expect(findings, isEmpty);
    });

    test(
      'orphaned rows produce one finding each and leave the database unchanged',
      () async {
        await _seedProblems(db, ids: ids, clock: FixedClock(t0));
        final Map<String, int> before = await _rowCounts(db);

        final List<IntegrityFinding> findings = _ok(
          await runIntegrityCheck(db),
        );
        expect(findings, hasLength(4));
        expect(_one(findings, 'record_fields').detail, contains('record'));
        expect(_one(findings, 'photos').detail, contains('missing'));
        expect(_one(findings, 'processing_jobs').detail, contains('record'));
        expect(_one(findings, 'records').detail, contains('tombstone'));
        for (final IntegrityFinding finding in findings) {
          expect(finding.entityId, isNotEmpty);
          expect(finding.detail, isNotEmpty);
        }

        expect(await _rowCounts(db), before);

        final List<IntegrityFinding> second = _ok(await runIntegrityCheck(db));
        expect(second, hasLength(4));
        expect(await _rowCounts(db), before);
      },
    );
  });

  test('running the check twice changes nothing on disk', () async {
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_integrity_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final AppDatabase onDisk = AppDatabase.open(directoryPath: directory.path);
    addTearDown(onDisk.close);
    await onDisk.customSelect('SELECT 1').get();
    await _seedProblems(
      onDisk,
      ids: UuidV7Service.sequence(FixedClock(t0)),
      clock: FixedClock(t0),
    );
    final Map<String, int> before = await _rowCounts(onDisk);
    final File sqlite = File('${directory.path}/tapture.sqlite');
    final int length = sqlite.lengthSync();

    _ok(await runIntegrityCheck(onDisk));
    _ok(await runIntegrityCheck(onDisk));

    expect(await _rowCounts(onDisk), before);
    expect(sqlite.lengthSync(), length);
  });
}

Future<void> _seedProblems(
  AppDatabase db, {
  required IdService ids,
  required Clock clock,
}) async {
  _ok(
    await insertRecordField(
      db,
      row: const RecordFieldsCompanion(
        recordId: Value<String>('record-gone'),
        fieldKey: Value<String>('serial'),
        valueRaw: Value<String>('SN-1'),
        source: Value<String>('typed'),
      ),
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
    ),
  );
  _ok(
    await upsertPhoto(
      db,
      row: PhotosCompanion(
        projectId: const Value<String>('p1'),
        captureSessionId: const Value<String>('session-1'),
        originalFilename: const Value<String>('IMG_001.jpg'),
        storedFilename: const Value<String>('img-001.jpg'),
        relativePath: const Value<String>(
          'photos/_unfiled/missing-integrity.jpg',
        ),
        photoType: const Value<String>('front'),
        sortOrder: const Value<int>(0),
        width: const Value<int>(1600),
        height: const Value<int>(1200),
        fileSize: const Value<int>(2048),
        mimeType: const Value<String>('image/jpeg'),
        sha256: const Value<String>('integrity-missing'),
        capturedAt: Value<DateTime>(clock.nowUtc()),
      ),
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
    ),
  );
  _ok(
    await upsertProcessingJob(
      db,
      row: ProcessingCompanion(
        recordId: const Value<String>('record-gone-job'),
        stage: const Value<String>('prepare'),
        status: const Value<ProcessingJobStatus>(ProcessingJobStatus.queued),
        queuedAt: Value<DateTime>(clock.nowUtc()),
      ),
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
    ),
  );
  _ok(
    await upsertRecord(
      db,
      row: RecordsCompanion(
        projectId: const Value<String>('p1'),
        templateId: const Value<String>('t1'),
        status: const Value<String>('deleted'),
        processingMode: const Value<String>('manual'),
        contextJson: const Value<String>('{}'),
        identityHash: const Value<String>('integrity-deleted'),
        source: const Value<String>('capture'),
        capturedAt: Value<DateTime>(clock.nowUtc()),
        capturedBy: const Value<String>('Ada'),
      ),
      clock: clock,
      deviceId: 'device-a',
      ids: ids,
    ),
  );
}

IntegrityFinding _one(List<IntegrityFinding> findings, String entityType) {
  final List<IntegrityFinding> matches = findings
      .where((IntegrityFinding finding) => finding.entityType == entityType)
      .toList();
  expect(matches, hasLength(1), reason: entityType);
  return matches.single;
}

Future<Map<String, int>> _rowCounts(AppDatabase db) async {
  final List<QueryRow> tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  final Map<String, int> counts = <String, int>{};
  for (final QueryRow table in tables) {
    final String name = table.read<String>('name');
    final QueryRow count = await db
        .customSelect('SELECT COUNT(*) AS n FROM "$name"')
        .getSingle();
    counts[name] = count.read<int>('n');
  }
  return counts;
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
