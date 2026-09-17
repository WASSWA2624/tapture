import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/sync_state.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() async {
    await db.close();
  });

  test('the unique triple holds one row per entity and device', () async {
    final VersionVectorRow first = _ok(
      await upsertVersionVector(
        db,
        entityType: 'records',
        entityId: 'rec-1',
        rev: 2,
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    final VersionVectorRow again = _ok(
      await upsertVersionVector(
        db,
        entityType: 'records',
        entityId: 'rec-1',
        rev: 5,
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    expect(again.id, first.id);
    expect(again.seenRev, 5);
    expect(await db.select(db.syncState).get(), hasLength(1));

    try {
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion(
              createdAt: Value<DateTime>(t0),
              updatedAt: Value<DateTime>(t0),
              updatedByDevice: const Value<String>('device-a'),
              entityType: const Value<String>('records'),
              entityId: const Value<String>('rec-1'),
              deviceId: const Value<String>('device-a'),
              seenRev: const Value<int>(9),
            ),
          );
      fail('expected a uniqueness failure');
    } on Object catch (error) {
      expect(storageFailureFrom(error).message, contains('already exists'));
    }
  });

  test('compareVectors covers all four relations including empty', () {
    expect(
      compareVectors(
        <String, int>{'a': 2, 'b': 1},
        <String, int>{'a': 2, 'b': 1},
      ),
      VectorRelation.equal,
    );
    expect(
      compareVectors(<String, int>{}, <String, int>{}),
      VectorRelation.equal,
    );
    expect(
      compareVectors(
        <String, int>{'a': 3, 'b': 1},
        <String, int>{'a': 2, 'b': 1},
      ),
      VectorRelation.dominates,
    );
    expect(
      compareVectors(<String, int>{'a': 1}, <String, int>{'a': 2, 'b': 1}),
      VectorRelation.dominated,
    );
    expect(
      compareVectors(<String, int>{}, <String, int>{'a': 1}),
      VectorRelation.dominated,
    );
    expect(
      compareVectors(
        <String, int>{'a': 2, 'b': 1},
        <String, int>{'a': 1, 'b': 2},
      ),
      VectorRelation.concurrent,
    );
  });

  test('an incoming entity is classified from one vector read', () async {
    _ok(
      await upsertVersionVector(
        db,
        entityType: 'records',
        entityId: 'rec-1',
        rev: 3,
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    _ok(
      await upsertVersionVector(
        db,
        entityType: 'records',
        entityId: 'rec-1',
        rev: 1,
        clock: FixedClock(t0),
        deviceId: 'device-b',
        ids: ids,
      ),
    );

    final Map<String, int> mine = _ok(
      await loadVersionVector(db, entityType: 'records', entityId: 'rec-1'),
    );
    expect(mine, <String, int>{'device-a': 3, 'device-b': 1});
    expect(
      compareVectors(mine, <String, int>{'device-a': 3, 'device-b': 1}),
      VectorRelation.equal,
    );
    expect(
      compareVectors(mine, <String, int>{'device-a': 2, 'device-b': 1}),
      VectorRelation.dominates,
    );
    expect(
      compareVectors(mine, <String, int>{'device-a': 3, 'device-b': 2}),
      VectorRelation.dominated,
    );
    expect(
      compareVectors(mine, <String, int>{'device-a': 2, 'device-b': 4}),
      VectorRelation.concurrent,
    );
  });

  test(
    'version 12 creates the version_vectors table with merge columns',
    () async {
      await db.close();
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture_sync_state_',
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
        await _columns(upgraded, 'version_vectors'),
        containsAll(<String>[
          'id',
          'created_at',
          'updated_at',
          'updated_by_device',
          'rev',
          'entity_type',
          'entity_id',
          'device_id',
          'seen_rev',
        ]),
      );
    },
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
