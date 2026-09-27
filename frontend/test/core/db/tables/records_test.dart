import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
  final DateTime t1 = t0.add(const Duration(seconds: 2));
  final DateTime t2 = t0.add(const Duration(seconds: 4));

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'paged listing by project and status, and lookup by identityHash',
    () async {
      _ok(
        await upsertRecord(
          db,
          row: _record(projectId: 'p1', identityHash: 'h-old', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertRecord(
          db,
          row: _record(projectId: 'p1', identityHash: 'h-mid', capturedAt: t1),
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final RecordRow newest = _ok(
        await upsertRecord(
          db,
          row: _record(projectId: 'p1', identityHash: 'h-new', capturedAt: t2),
          clock: FixedClock(t2),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertRecord(
          db,
          row: _record(
            projectId: 'p1',
            identityHash: 'h-draft',
            status: 'draft',
            capturedAt: t2,
          ),
          clock: FixedClock(t2),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertRecord(
          db,
          row: _record(
            projectId: 'p2',
            identityHash: 'h-other',
            capturedAt: t2,
          ),
          clock: FixedClock(t2),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final List<String> page = _ok(
        await listRecordsByProjectAndStatus(
          db,
          projectId: 'p1',
          status: 'captured',
          offset: 0,
          limit: 2,
        ),
      ).map((RecordRow row) => row.identityHash).toList();
      expect(page, <String>['h-new', 'h-mid']);

      final List<String> rest = _ok(
        await listRecordsByProjectAndStatus(
          db,
          projectId: 'p1',
          status: 'captured',
          offset: 2,
          limit: 2,
        ),
      ).map((RecordRow row) => row.identityHash).toList();
      expect(rest, <String>['h-old']);

      final RecordRow? found = _ok(
        await lookupRecordByIdentityHash(db, identityHash: 'h-new'),
      );
      expect(found?.id, newest.id);
    },
  );

  test(
    'the project-status list is served by records_by_project_status',
    () async {
      _ok(
        await upsertRecord(
          db,
          row: _record(projectId: 'p1', identityHash: 'h1', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertRecord(
          db,
          row: _record(
            projectId: 'p1',
            identityHash: 'h2',
            status: 'draft',
            capturedAt: t0,
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertRecord(
          db,
          row: _record(projectId: 'p2', identityHash: 'h3', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final List<QueryRow> plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM records '
            "WHERE project_id = 'p1' AND status = 'captured' "
            'ORDER BY captured_at DESC',
          )
          .get();
      final String details = plan
          .map((QueryRow row) => row.read<String>('detail'))
          .join('; ');
      expect(details, contains('records_by_project_status'));
    },
  );

  test('version 5 creates the records table with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_records_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final File seed = File('${directory.path}/tapture.sqlite');
    _seedVersion1(seed);

    final AppDatabase upgraded = AppDatabase.open(
      directoryPath: directory.path,
    );
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();

    expect(
      await _columns(upgraded, 'records'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'project_id',
        'template_id',
        'template_row_id',
        'status',
        'processing_mode',
        'context_json',
        'identity_hash',
        'source',
        'captured_at',
        'captured_by',
        'gps_lat',
        'gps_lon',
        'approved_at',
        'approved_by',
        'record_number',
      ]),
    );
  });

  group('writeRecordStatus', () {
    late RecordRow record;

    setUp(() async {
      record = _ok(
        await upsertRecord(
          db,
          row: _record(projectId: 'p1', identityHash: 'h1', capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
    });

    test(
      'moves the status, bumps rev and appends one status audit row',
      () async {
        await writeRecordStatus(
          db,
          recordId: record.id,
          status: 'needsReview',
          previousStatus: 'captured',
          clock: FixedClock(t1),
          deviceId: 'device-b',
          operator: 'Ada',
          reason: 'value edited',
        );

        final RecordRow stored = await _stored(db, record.id);
        expect(stored.status, 'needsReview');
        expect(stored.rev, record.rev + 1);
        expect(stored.updatedAt.toUtc(), t1);
        expect(stored.updatedByDevice, 'device-b');
        expect(stored.approvedAt, isNull);
        expect(stored.approvedBy, isNull);

        final List<AuditLogData> audit = await db.select(db.auditLog).get();
        expect(audit, hasLength(1));
        expect(audit.single.entityType, 'records');
        expect(audit.single.entityId, record.id);
        expect(audit.single.action, AuditAction.updated);
        expect(audit.single.fieldKey, recordStatusAuditKey);
        expect(audit.single.previousValue, 'captured');
        expect(audit.single.newValue, 'needsReview');
        expect(audit.single.reason, 'value edited');
        expect(audit.single.operator, 'Ada');
        expect(audit.single.device, 'device-b');
        expect(audit.single.at.toUtc(), t1);
      },
    );

    test(
      'approving stamps approved_at and approved_by, and leaving approved keeps them',
      () async {
        await writeRecordStatus(
          db,
          recordId: record.id,
          status: 'approved',
          previousStatus: 'needsReview',
          clock: FixedClock(t1),
          operator: 'Ada',
        );
        RecordRow stored = await _stored(db, record.id);
        expect(stored.status, 'approved');
        expect(stored.approvedAt?.toUtc(), t1);
        expect(stored.approvedBy, 'Ada');

        await writeRecordStatus(
          db,
          recordId: record.id,
          status: 'needsReview',
          previousStatus: 'approved',
          clock: FixedClock(t2),
          operator: 'Bo',
        );
        stored = await _stored(db, record.id);
        expect(stored.status, 'needsReview');
        expect(stored.approvedAt?.toUtc(), t1);
        expect(stored.approvedBy, 'Ada');
        expect(stored.rev, record.rev + 2);
      },
    );

    test('legacy spellings are stored and audited canonically', () async {
      await writeRecordStatus(
        db,
        recordId: record.id,
        status: 'NEEDS_REVIEW',
        previousStatus: 'CAPTURED',
        clock: FixedClock(t1),
      );
      expect((await _stored(db, record.id)).status, 'needsReview');
      final AuditLogData audit = await db.select(db.auditLog).getSingle();
      expect(audit.previousValue, 'captured');
      expect(audit.newValue, 'needsReview');
    });

    test(
      'joins the caller transaction, so a later failure undoes the move and its audit',
      () async {
        final Result<void> result = await runInTransaction(db, () async {
          await writeRecordStatus(
            db,
            recordId: record.id,
            status: 'deleted',
            previousStatus: 'captured',
            clock: FixedClock(t1),
          );
          throw const StorageFailure(message: 'tombstone failed');
        });

        expect(result, isA<FailureResult<void>>());
        expect((await _stored(db, record.id)).status, 'captured');
        expect(await db.select(db.auditLog).get(), isEmpty);
      },
    );

    test(
      'a record that is not on this device fails without an audit row',
      () async {
        final Result<void> result = await runInTransaction(
          db,
          () => writeRecordStatus(
            db,
            recordId: 'missing',
            status: 'approved',
            previousStatus: 'needsReview',
          ),
        );

        result.fold(
          (Failure failure) => expect(failure, isA<StorageFailure>()),
          (_) => fail('expected a failure'),
        );
        expect(await db.select(db.auditLog).get(), isEmpty);
      },
    );
  });

  test('canonicalRecordStatus folds case and underscores only', () {
    expect(canonicalRecordStatus('NEEDS_REVIEW'), 'needsReview');
    expect(canonicalRecordStatus('needs_review'), 'needsReview');
    expect(canonicalRecordStatus('needsReview'), 'needsReview');
    expect(canonicalRecordStatus('CAPTURED'), 'captured');
    expect(canonicalRecordStatus('Deleted'), 'deleted');
    expect(canonicalRecordStatus('needs review'), 'needs review');
    expect(canonicalRecordStatus('exported'), 'exported');
  });

  test('a new record takes the next number in its project', () async {
    final RecordRow first = _ok(
      await upsertRecord(
        db,
        row: _record(projectId: 'p1', identityHash: 'n1', capturedAt: t0),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    final RecordRow second = _ok(
      await upsertRecord(
        db,
        row: _record(projectId: 'p1', identityHash: 'n2', capturedAt: t0),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    final RecordRow other = _ok(
      await upsertRecord(
        db,
        row: _record(projectId: 'p2', identityHash: 'n3', capturedAt: t0),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    expect(first.recordNumber, 1);
    expect(second.recordNumber, 2);
    expect(other.recordNumber, 1);

    final RecordRow updated = _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          id: Value<String>(first.id),
          status: const Value<String>('queued'),
        ),
        clock: FixedClock(t1),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    expect(updated.recordNumber, 1);
  });
}

Future<RecordRow> _stored(AppDatabase db, String id) {
  return (db.select(
    db.records,
  )..where(($RecordsTable tbl) => tbl.id.equals(id))).getSingle();
}

RecordsCompanion _record({
  required String projectId,
  required String identityHash,
  required DateTime capturedAt,
  String status = 'captured',
}) {
  return RecordsCompanion(
    projectId: Value<String>(projectId),
    templateId: const Value<String>('t1'),
    status: Value<String>(status),
    processingMode: const Value<String>('manual'),
    contextJson: const Value<String>('{}'),
    identityHash: Value<String>(identityHash),
    source: const Value<String>('capture'),
    capturedAt: Value<DateTime>(capturedAt),
    capturedBy: const Value<String>('Ada'),
  );
}

void _seedVersion1(File file) {
  file.parent.createSync(recursive: true);
  final Database database = sqlite3.open(file.path);
  database.execute('PRAGMA user_version = 1');
  database.dispose();
}

Future<Set<String>> _columns(AppDatabase db, String table) async {
  final List<QueryRow> info = await db
      .customSelect('PRAGMA table_info("$table")')
      .get();
  return <String>{for (final QueryRow row in info) row.read<String>('name')};
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
