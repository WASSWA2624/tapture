import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/exports.dart';
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
    'completing an export writes one row and versions per project',
    () async {
      final ExportRow first = _ok(
        await completeExport(
          db,
          produce: () async => _export(
            projectId: 'p1',
            path: 'exports/p1/v1.zip',
            hash: 'hash-1',
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(first.version, 1);
      expect(first.filePath, 'exports/p1/v1.zip');
      expect(first.fileHash, 'hash-1');
      expect(await db.select(db.exports).get(), hasLength(1));

      final ExportRow second = _ok(
        await completeExport(
          db,
          produce: () async => _export(
            projectId: 'p1',
            path: 'exports/p1/v2.zip',
            hash: 'hash-2',
          ),
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(second.version, 2);
      expect(second.id, isNot(first.id));

      final ExportRow other = _ok(
        await completeExport(
          db,
          produce: () async => _export(
            projectId: 'p2',
            path: 'exports/p2/v1.zip',
            hash: 'hash-p2',
          ),
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(other.version, 1);

      final Result<ExportRow> rewritten = await completeExport(
        db,
        produce: () async => ExportsCompanion(
          id: Value<String>(first.id),
          projectId: const Value<String>('p1'),
          formats: Value<String>(jsonEncode(<String>['xlsx'])),
          filters: Value<String>(jsonEncode(<String, String>{'status': 'all'})),
          recordCount: const Value<int>(1),
          filePath: const Value<String>('exports/p1/v1-rewritten.zip'),
          fileHash: const Value<String>('hash-rewritten'),
          createdBy: const Value<String>('Ada'),
        ),
        clock: FixedClock(t2),
        deviceId: 'device-a',
        ids: ids,
      );
      expect(
        rewritten.fold((Failure failure) => failure, (_) => null),
        isA<StorageFailure>(),
      );
      expect(
        (await (db.select(db.exports)
                  ..where(($ExportsTable tbl) => tbl.id.equals(first.id)))
                .getSingle())
            .fileHash,
        'hash-1',
      );
    },
  );

  test('history for a project lists newest first through the index', () async {
    _ok(
      await completeExport(
        db,
        produce: () async =>
            _export(projectId: 'p1', path: 'exports/p1/v1.zip', hash: 'h1'),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    final ExportRow newest = _ok(
      await completeExport(
        db,
        produce: () async =>
            _export(projectId: 'p1', path: 'exports/p1/v2.zip', hash: 'h2'),
        clock: FixedClock(t2),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    _ok(
      await completeExport(
        db,
        produce: () async =>
            _export(projectId: 'p1', path: 'exports/p1/v3.zip', hash: 'h3'),
        clock: FixedClock(t1),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    _ok(
      await completeExport(
        db,
        produce: () async =>
            _export(projectId: 'p2', path: 'exports/p2/v1.zip', hash: 'other'),
        clock: FixedClock(t2),
        deviceId: 'device-a',
        ids: ids,
      ),
    );

    final List<String> page = _ok(
      await listExportsForProject(db, projectId: 'p1', offset: 0, limit: 2),
    ).map((ExportRow row) => row.fileHash).toList();
    expect(page, <String>['h2', 'h3']);
    expect(newest.fileHash, 'h2');

    final List<QueryRow> plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN SELECT * FROM exports '
          "WHERE project_id = 'p1' ORDER BY created_at DESC",
        )
        .get();
    expect(
      plan.map((QueryRow row) => row.read<String>('detail')).join('; '),
      contains('exports_by_project_created'),
    );
  });

  test('an abandoned export writes no row', () async {
    final Result<ExportRow> failed = await completeExport(
      db,
      produce: () async {
        throw const StorageFailure(
          message: 'The disk is full.',
          recoveryAction: 'Free up space, then export again.',
        );
      },
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    expect(
      failed.fold((Failure failure) => failure, (_) => null),
      isA<StorageFailure>(),
    );
    expect(await db.select(db.exports).get(), isEmpty);

    final Result<ExportRow> incomplete = await completeExport(
      db,
      produce: () async => ExportsCompanion(
        projectId: const Value<String>('p1'),
        formats: Value<String>(jsonEncode(<String>['xlsx'])),
        filters: Value<String>(jsonEncode(<String, String>{'status': 'all'})),
        recordCount: const Value<int>(3),
        createdBy: const Value<String>('Ada'),
      ),
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    expect(
      incomplete.fold((Failure failure) => failure, (_) => null),
      isA<StorageFailure>(),
    );
    expect(await db.select(db.exports).get(), isEmpty);
  });

  test('version 11 creates the exports table with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_exports_',
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
      await _columns(upgraded, 'exports'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'project_id',
        'version',
        'formats',
        'filters',
        'record_count',
        'file_path',
        'file_hash',
        'created_by',
      ]),
    );
  });
}

ExportsCompanion _export({
  required String projectId,
  required String path,
  required String hash,
}) {
  return ExportsCompanion(
    projectId: Value<String>(projectId),
    formats: Value<String>(jsonEncode(<String>['xlsx', 'csv'])),
    filters: Value<String>(jsonEncode(<String, String>{'status': 'captured'})),
    recordCount: const Value<int>(3),
    filePath: Value<String>(path),
    fileHash: Value<String>(hash),
    createdBy: const Value<String>('Ada'),
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
