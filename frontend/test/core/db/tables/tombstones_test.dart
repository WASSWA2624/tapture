import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late _TombstoneDao dao;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
    dao = _TombstoneDao(
      db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('softDelete writes one tombstone and keeps the row', () async {
    final Tombstone row = _ok(
      await dao.upsert(
        TombstonesCompanion(
          entityType: const Value<String>('records'),
          entityId: const Value<String>('r1'),
          deletedAt: Value<DateTime>(t0),
          deletedByDevice: const Value<String>('device-a'),
          reason: const Value<String>('gone'),
        ),
      ),
    );

    _ok(await dao.softDelete(row.id, reason: 'remove'));

    expect(_ok(await dao.getById(row.id)), isNotNull);
    final List<Tombstone> marks = await (db.select(
      db.tombstones,
    )..where(($TombstonesTable tbl) => tbl.entityId.equals(row.id))).get();
    expect(marks, hasLength(1));
    expect(marks.single.entityType, 'tombstones');
    expect(marks.single.reason, 'remove');
  });

  test(
    'a failed delete writes neither a tombstone nor a hard delete',
    () async {
      final Tombstone row = _ok(
        await dao.upsert(
          TombstonesCompanion(
            entityType: const Value<String>('records'),
            entityId: const Value<String>('r1'),
            deletedAt: Value<DateTime>(t0),
            deletedByDevice: const Value<String>('device-a'),
            reason: const Value<String>('gone'),
          ),
        ),
      );

      final Result<void> result = await runInTransaction(db, () async {
        _ok(await dao.softDelete(row.id, reason: 'remove'));
        throw StateError('fail');
      });
      expect(
        result.fold((Failure failure) => failure, (_) => null),
        isA<StorageFailure>(),
      );
      expect(_ok(await dao.getById(row.id))?.entityId, 'r1');
      final List<Tombstone> marks = await (db.select(
        db.tombstones,
      )..where(($TombstonesTable tbl) => tbl.entityId.equals(row.id))).get();
      expect(marks, isEmpty);
    },
  );

  test('version 2 creates the tombstones table with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_tombstones_',
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

    final Set<String> columns = await _columns(upgraded, 'tombstones');
    expect(
      columns,
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'entity_type',
        'entity_id',
        'deleted_at',
        'deleted_by_device',
        'reason',
      ]),
    );
  });

  test(
    'removeTombstone lifts only the named tombstone and a repeat is a no-op',
    () async {
      await writeTombstone(
        db,
        entityType: 'records',
        entityId: 'r1',
        reason: 'deleted',
        clock: FixedClock(t0),
      );
      await writeTombstone(
        db,
        entityType: 'photos',
        entityId: 'r1',
        reason: 'removed',
        clock: FixedClock(t0),
      );
      await writeTombstone(
        db,
        entityType: 'records',
        entityId: 'r2',
        reason: 'deleted',
        clock: FixedClock(t0),
      );

      await removeTombstone(db, entityType: 'records', entityId: 'r1');
      await removeTombstone(db, entityType: 'records', entityId: 'r1');

      final List<Tombstone> left =
          await (db.select(db.tombstones)
                ..orderBy(<OrderClauseGenerator<$TombstonesTable>>[
                  ($TombstonesTable tbl) => OrderingTerm.asc(tbl.entityType),
                  ($TombstonesTable tbl) => OrderingTerm.asc(tbl.entityId),
                ]))
              .get();
      expect(
        left.map((Tombstone row) => '${row.entityType}/${row.entityId}'),
        <String>['photos/r1', 'records/r2'],
      );
    },
  );

  test('removeTombstone tells a watched tombstone query', () async {
    await writeTombstone(
      db,
      entityType: 'records',
      entityId: 'r1',
      reason: 'deleted',
      clock: FixedClock(t0),
    );
    final Stream<List<Tombstone>> watched = db.select(db.tombstones).watch();
    final Future<void> emptied = expectLater(
      watched.map((List<Tombstone> rows) => rows.length),
      emitsThrough(0),
    );
    await removeTombstone(db, entityType: 'records', entityId: 'r1');
    await emptied;
  });

  test('a restore inside a failed transaction keeps the tombstone', () async {
    await writeTombstone(
      db,
      entityType: 'records',
      entityId: 'r1',
      reason: 'deleted',
      clock: FixedClock(t0),
    );
    final Result<void> result = await runInTransaction(db, () async {
      await removeTombstone(db, entityType: 'records', entityId: 'r1');
      throw const StorageFailure(message: 'status write failed');
    });
    expect(result, isA<FailureResult<void>>());
    expect(await db.select(db.tombstones).get(), hasLength(1));
  });
}

final class _TombstoneDao extends BaseDao<Tombstones, Tombstone> {
  _TombstoneDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.tombstones);
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
