import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/merge.dart';
import 'package:tapture/core/db/tables/sync_state.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
  final DateTime t1 = t0.add(const Duration(seconds: 2));

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'a session keeps its undo path and unresolved conflicts survive a restart',
    () async {
      await db.close();
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture_merge_session_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final AppDatabase first = AppDatabase.open(directoryPath: directory.path);
      final UuidV7Service firstIds = UuidV7Service.sequence(FixedClock(t0));
      final MergeSession session = _ok(
        await insertMergeSession(
          first,
          row: _session(importedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: firstIds,
        ),
      );
      expect(session.undoSnapshotPath, 'snapshots/merge-1.zip');
      final MergeConflict conflict = _ok(
        await insertMergeConflict(
          first,
          row: _conflict(
            sessionId: session.id,
            mineValue: '  SN-001  ',
            resolution: 'takeTheirs',
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: firstIds,
        ),
      );
      expect(conflict.mineValue, '  SN-001  ');
      expect(conflict.resolution, isNull);
      await first.close();

      final AppDatabase restarted = AppDatabase.open(
        directoryPath: directory.path,
      );
      addTearDown(restarted.close);
      await restarted.customSelect('SELECT 1').get();

      final MergeSession kept = await (restarted.select(
        restarted.merge,
      )..where(($MergeTable tbl) => tbl.id.equals(session.id))).getSingle();
      expect(kept.undoSnapshotPath, 'snapshots/merge-1.zip');
      expect(kept.bundleName, 'site-a.tapture');
      expect(
        _ok(
          await listUnresolvedMergeConflicts(restarted, sessionId: session.id),
        ).map((MergeConflict row) => row.id).toList(),
        <String>[conflict.id],
      );
    },
  );

  test(
    'the unresolved queue is listed by session and empty resolution',
    () async {
      final MergeSession session = _ok(
        await insertMergeSession(
          db,
          row: _session(importedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final MergeConflict open = _ok(
        await insertMergeConflict(
          db,
          row: _conflict(sessionId: session.id, fieldKey: 'serial'),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final MergeConflict later = _ok(
        await insertMergeConflict(
          db,
          row: _conflict(sessionId: session.id, fieldKey: 'make'),
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await resolveMergeConflict(
          db,
          id: later.id,
          resolution: 'keepMine',
          resolvedBy: 'Ada',
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      expect(
        _ok(
          await listUnresolvedMergeConflicts(db, sessionId: session.id),
        ).map((MergeConflict row) => row.id).toList(),
        <String>[open.id],
      );

      final List<QueryRow> plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM merge_conflicts '
            "WHERE session_id = '${session.id}' AND resolution IS NULL",
          )
          .get();
      expect(
        plan.map((QueryRow row) => row.read<String>('detail')).join('; '),
        contains('merge_conflicts_by_session_resolution'),
      );
    },
  );

  test(
    'resolving records the operator and timestamp and bumps the vector',
    () async {
      final MergeSession session = _ok(
        await insertMergeSession(
          db,
          row: _session(importedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final MergeConflict conflict = _ok(
        await insertMergeConflict(
          db,
          row: _conflict(
            sessionId: session.id,
            entityId: 'rec-1',
            mineValue: '  SN-001  ',
          ),
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
          rev: 4,
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final MergeConflict resolved = _ok(
        await resolveMergeConflict(
          db,
          id: conflict.id,
          resolution: 'keepMine',
          resolvedBy: 'Ada',
          clock: FixedClock(t1),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(resolved.resolution, 'keepMine');
      expect(resolved.resolvedBy, 'Ada');
      expect(resolved.resolvedAt!.isAtSameMomentAs(t1), isTrue);
      expect(resolved.mineValue, '  SN-001  ');
      expect(
        _ok(
          await loadVersionVector(db, entityType: 'records', entityId: 'rec-1'),
        ),
        <String, int>{'device-a': 5},
      );
    },
  );

  test('version 12 creates the merge tables with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_merge_',
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
      await _columns(upgraded, 'merge_sessions'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'bundle_name',
        'source_device',
        'imported_at',
        'counts',
        'status',
        'undo_snapshot_path',
      ]),
    );
    expect(
      await _columns(upgraded, 'merge_conflicts'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'session_id',
        'entity_type',
        'entity_id',
        'field_key',
        'mine_value',
        'theirs_value',
        'mine_meta',
        'theirs_meta',
        'resolution',
        'resolved_at',
        'resolved_by',
      ]),
    );
  });
}

MergeCompanion _session({required DateTime importedAt}) {
  return MergeCompanion(
    bundleName: const Value<String>('site-a.tapture'),
    sourceDevice: const Value<String>('device-b'),
    importedAt: Value<DateTime>(importedAt),
    counts: Value<String>(jsonEncode(<String, int>{'records': 3, 'photos': 1})),
    status: const Value<String>('imported'),
    undoSnapshotPath: const Value<String>('snapshots/merge-1.zip'),
  );
}

MergeConflictsCompanion _conflict({
  required String sessionId,
  String entityId = 'rec-1',
  String fieldKey = 'serial',
  String mineValue = 'SN-001',
  String? resolution,
}) {
  return MergeConflictsCompanion(
    sessionId: Value<String>(sessionId),
    entityType: const Value<String>('records'),
    entityId: Value<String>(entityId),
    fieldKey: Value<String>(fieldKey),
    mineValue: Value<String>(mineValue),
    theirsValue: const Value<String>('SN-002'),
    mineMeta: Value<String>(jsonEncode(<String, String>{'by': 'Ada'})),
    theirsMeta: Value<String>(jsonEncode(<String, String>{'by': 'Ben'})),
    resolution: resolution == null
        ? const Value<String?>.absent()
        : Value<String?>(resolution),
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
