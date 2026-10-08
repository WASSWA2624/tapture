import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/context.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
  final DateTime t1 = t0.add(const Duration(seconds: 2));

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  test('setting a higher level clears every lower level', () async {
    await setContextLevel(
      db,
      projectId: 'p1',
      level: 1,
      value: 'North',
      clock: FixedClock(t0),
      deviceId: 'device-a',
    );
    await setContextLevel(
      db,
      projectId: 'p1',
      level: 2,
      value: 'Clinic',
      clock: FixedClock(t0),
      deviceId: 'device-a',
    );
    await setContextLevel(
      db,
      projectId: 'p1',
      level: 3,
      value: 'Ward A',
      clock: FixedClock(t0),
      deviceId: 'device-a',
    );

    await setContextLevel(
      db,
      projectId: 'p1',
      level: 1,
      value: 'South',
      clock: FixedClock(t1),
      deviceId: 'device-a',
    );

    final List<ContextStateRow> rows = await db.select(db.contextState).get();
    expect(rows, hasLength(1));
    expect(rows.single.level, 1);
    expect(rows.single.value, 'South');
    expect(rows.where((ContextStateRow row) => row.level > 1), isEmpty);
  });

  test('a context preset round-trips name and values', () async {
    const Map<String, String> values = <String, String>{
      'district': 'North',
      'facility': 'Clinic',
    };
    final ContextPreset saved = await upsertContextPreset(
      db,
      projectId: 'p1',
      name: 'Clinic morning',
      values: jsonEncode(values),
      clock: FixedClock(t0),
      deviceId: 'device-a',
    );

    expect(saved.name, 'Clinic morning');
    expect(saved.projectId, 'p1');
    final Object? decoded = jsonDecode(saved.values) as Object?;
    expect(decoded, values);

    final List<ContextPreset> rows = await db.select(db.contextPresets).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, saved.id);
  });

  test(
    'deleting a definition writes one tombstone, keeps the row and hides it from the live read',
    () async {
      await db.customStatement(
        'INSERT INTO context_definitions '
        '(id, created_at, updated_at, updated_by_device, rev, project_id, '
        'level, field_key, label) VALUES '
        "('c1', 1, 1, 'device-a', 1, 'p1', 1, 'district', 'District'), "
        "('c2', 1, 1, 'device-a', 1, 'p1', 2, 'facility', 'Facility')",
      );

      await db.transaction(() async {
        await deleteContextDefinition(
          db,
          id: 'c2',
          reason: 'Level removed.',
          clock: FixedClock(t1),
          deviceId: 'device-a',
        );
        await deleteContextDefinition(
          db,
          id: 'c2',
          reason: 'Level removed again.',
          clock: FixedClock(t1),
          deviceId: 'device-a',
        );
      });

      expect(await db.select(db.context).get(), hasLength(2));
      final List<Tombstone> tombstones = await db.select(db.tombstones).get();
      expect(tombstones, hasLength(1));
      expect(tombstones.single.entityType, 'context_definitions');
      expect(tombstones.single.entityId, 'c2');
      expect(tombstones.single.deletedByDevice, 'device-a');
      final List<ContextData> live = await liveContextDefinitions(
        db,
        projectId: 'p1',
      ).get();
      expect(live.map((ContextData row) => row.id), <String>['c1']);
    },
  );

  test(
    'deleting a preset keeps its row, and one saved again under that name reads back alone',
    () async {
      final ContextPreset first = await upsertContextPreset(
        db,
        projectId: 'p1',
        name: 'Clinic morning',
        values: '{}',
        clock: FixedClock(t0),
        deviceId: 'device-a',
      );
      await deleteContextPreset(
        db,
        id: first.id,
        reason: 'Removed by the operator.',
        clock: FixedClock(t1),
        deviceId: 'device-a',
      );
      final ContextPreset again = await upsertContextPreset(
        db,
        projectId: 'p1',
        name: 'Clinic morning',
        values: '{"district":"North"}',
        clock: FixedClock(t1),
        deviceId: 'device-a',
      );

      expect(again.id, isNot(first.id));
      expect(await db.select(db.contextPresets).get(), hasLength(2));
      expect(await db.select(db.tombstones).get(), hasLength(1));
      final List<ContextPreset> live = await liveContextPresets(
        db,
        projectId: 'p1',
      ).get();
      expect(live.map((ContextPreset row) => row.id), <String>[again.id]);
    },
  );

  test(
    'the live preset watch sees a delete that only writes a tombstone',
    () async {
      final ContextPreset saved = await upsertContextPreset(
        db,
        projectId: 'p1',
        name: 'Ward round',
        values: '{}',
        clock: FixedClock(t0),
        deviceId: 'device-a',
      );
      final Stream<List<ContextPreset>> watched = liveContextPresets(
        db,
        projectId: 'p1',
      ).watch();
      final Future<void> emptied = watched.firstWhere(
        (List<ContextPreset> rows) => rows.isEmpty,
      );

      await deleteContextPreset(
        db,
        id: saved.id,
        reason: 'Removed by the operator.',
        clock: FixedClock(t1),
        deviceId: 'device-a',
      );

      await expectLater(emptied, completes);
    },
  );

  test('version 3 creates the context tables with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_context_',
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
      await _columns(upgraded, 'context_definitions'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'project_id',
        'level',
        'field_key',
        'label',
      ]),
    );
    expect(
      await _columns(upgraded, 'context_state'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'project_id',
        'level',
        'value',
        'set_at',
      ]),
    );
    expect(
      await _columns(upgraded, 'context_presets'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'name',
        'project_id',
        'values',
      ]),
    );
  });
}

void _seedVersion1(File file) {
  file.parent.createSync(recursive: true);
  final Database database = sqlite3.open(file.path);
  database.execute('PRAGMA user_version = 1');
  database.close();
}

Future<Set<String>> _columns(AppDatabase db, String table) async {
  final List<QueryRow> info = await db
      .customSelect('PRAGMA table_info("$table")')
      .get();
  return <String>{for (final QueryRow row in info) row.read<String>('name')};
}
