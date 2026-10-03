import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/bundle/bundle_format.dart';
import 'package:tapture/core/bundle/bundle_tables.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/version_vector_schema.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'package_files.dart';

/// Publishes durable pre-merge rows and restores only the rows a merge changed.
final class MergeSnapshotStore {
  /// Uses the same transaction and file boundary as the package importer.
  const MergeSnapshotStore(this.db, this.files);

  /// Database participating in the package transaction.
  final AppDatabase db;

  /// Durable snapshot and evidence storage.
  final PackageFiles files;

  /// A project and any incoming global rows it may change, excluding audit.
  Future<SnapshotRows> capture(String projectId, SnapshotRows incoming) async {
    final BundleTables? project = await BundleTables.read(db, projectId);
    if (project == null) {
      throw StorageFailure(
        localizedMessage: Copy.messages.packageProjectMissing,
        localizedRecovery: Copy.messages.importFailedRecovery,
      );
    }
    final SnapshotRows rows = <String, List<Map<String, Object?>>>{
      for (final MapEntry<String, List<Map<String, Object?>>> table
          in project.rows.entries)
        if (table.key != 'audit_log')
          table.key: List<Map<String, Object?>>.of(table.value),
    };
    for (final String table in BundleFormat.insertOrder) {
      if (table == 'audit_log') {
        continue;
      }
      final Set<Object?> present = <Object?>{
        for (final Map<String, Object?> row
            in rows[table] ?? const <Map<String, Object?>>[])
          row['id'],
      };
      final List<String> missing = <String>[
        for (final Map<String, Object?> row
            in incoming[table] ?? const <Map<String, Object?>>[])
          if (!present.contains(row['id'])) row['id']! as String,
      ];
      for (final List<String> ids in _chunks(missing)) {
        final List<QueryRow> found = await db
            .customSelect(
              'SELECT * FROM $table WHERE id IN (${List<String>.filled(ids.length, '?').join(',')})',
              variables: <Variable<Object>>[
                for (final String id in ids) Variable<String>(id),
              ],
            )
            .get();
        rows.putIfAbsent(table, () => <Map<String, Object?>>[]).addAll(
          <Map<String, Object?>>[
            for (final QueryRow row in found) Map<String, Object?>.of(row.data),
          ],
        );
      }
    }
    final List<QueryRow> conflicts = await db
        .customSelect(
          'SELECT * FROM merge_conflicts WHERE session_id IN '
          "(SELECT id FROM merge_sessions WHERE json_extract(counts, '\$.project_id') = ?)",
          variables: <Variable<Object>>[Variable<String>(projectId)],
        )
        .get();
    rows['merge_conflicts'] = <Map<String, Object?>>[
      for (final QueryRow row in conflicts) Map<String, Object?>.of(row.data),
    ];
    final List<Map<String, Object?>> vectors = <Map<String, Object?>>[];
    for (final MapEntry<String, List<Map<String, Object?>>> table
        in rows.entries) {
      final List<String> ids = <String>[
        for (final Map<String, Object?> row in table.value)
          row['id']! as String,
      ];
      for (final List<String> chunk in _chunks(ids)) {
        final List<QueryRow> found = await db
            .customSelect(
              'SELECT * FROM version_vectors WHERE entity_type = ? AND entity_id IN '
              '(${List<String>.filled(chunk.length, '?').join(',')})',
              variables: <Variable<Object>>[
                Variable<String>(table.key),
                for (final String id in chunk) Variable<String>(id),
              ],
            )
            .get();
        vectors.addAll(<Map<String, Object?>>[
          for (final QueryRow row in found) Map<String, Object?>.of(row.data),
        ]);
      }
    }
    rows['version_vectors'] = vectors;
    return rows;
  }

  /// Writes atomically before the database commits. Encoding runs off-thread.
  Future<void> publish({
    required String path,
    required String projectId,
    required SnapshotRows before,
    required SnapshotRows after,
    required List<String> importedFiles,
  }) async {
    final Uint8List bytes = _valueOf(
      await runIsolate(_encode, (
        projectId: projectId,
        before: before,
        after: after,
        importedFiles: importedFiles,
      )),
    );
    _valueOf(await files.write(path, bytes));
  }

  /// Reads and validates the snapshot without trusting its table or column names.
  Future<MergeSnapshot> read(String path) async {
    final Uint8List bytes = _valueOf(await files.read(path));
    return _valueOf(await runIsolate(_decode, bytes));
  }

  /// Fails before restoration if an affected row was edited since this merge.
  Future<void> ensureUnchanged(MergeSnapshot snapshot) async {
    for (final String table in snapshot.after.keys) {
      if (table == 'version_vectors') continue;
      final Map<String, Map<String, Object?>> before = _indexed(
        snapshot.before[table]!,
      );
      final Map<String, Map<String, Object?>> after = _indexed(
        snapshot.after[table]!,
      );
      for (final String id in <String>{...before.keys, ...after.keys}) {
        final QueryRow? current = await db
            .customSelect(
              'SELECT * FROM $table WHERE id = ?',
              variables: <Variable<Object>>[Variable<String>(id)],
            )
            .getSingleOrNull();
        if (!_equal(current?.data, after[id])) {
          throw ValidationFailure(
            localizedMessage: Copy.messages.mergeUndoChanged,
            localizedRecovery: Copy.messages.mergeUndoChangedRecovery,
          );
        }
      }
    }
  }

  /// Restores in dependency order. Audit rows remain append-only.
  Future<void> restore(
    MergeSnapshot snapshot, {
    DateTime? at,
    String? deviceId,
  }) async {
    final List<String> order = <String>[
      ...BundleFormat.insertOrder.where((String table) => table != 'audit_log'),
      'merge_conflicts',
    ];
    await VersionVectorSchema.remoteWrites(db, () async {
      for (final String table in order.reversed) {
        final Map<String, Map<String, Object?>> before = _indexed(
          snapshot.before[table] ?? const <Map<String, Object?>>[],
        );
        for (final Map<String, Object?> row
            in snapshot.after[table] ?? const <Map<String, Object?>>[]) {
          if (!before.containsKey(row['id'])) {
            await db.customStatement(
              'DELETE FROM $table WHERE id = ?',
              <Object?>[row['id']],
            );
          }
        }
      }
      for (final String table in order) {
        final List<Map<String, Object?>> rows =
            snapshot.before[table] ?? const <Map<String, Object?>>[];
        if (rows.isEmpty) {
          continue;
        }
        final Set<String> columns = <String>{
          for (final QueryRow row
              in await db.customSelect('PRAGMA table_info($table)').get())
            row.read<String>('name'),
        };
        for (final Map<String, Object?> row in rows) {
          if (row.keys.any((String key) => !columns.contains(key))) {
            throw const CorruptionFailure();
          }
          final List<String> names = row.keys.toList();
          final List<String> assignments = <String>[
            for (final String name in names)
              if (name != 'id') '"$name" = excluded."$name"',
          ];
          await db.customStatement(
            'INSERT INTO $table (${names.map((String name) => '"$name"').join(',')}) '
            'VALUES (${List<String>.filled(names.length, '?').join(',')}) '
            'ON CONFLICT(id) DO UPDATE SET ${assignments.join(',')}',
            <Object?>[for (final String name in names) row[name]],
          );
        }
      }
    });
    if (at != null && deviceId != null) {
      for (final String table in BundleFormat.insertOrder) {
        if (table == 'audit_log' || table == 'tombstones') continue;
        final Map<String, Map<String, Object?>> after = _indexed(
          snapshot.after[table] ?? const <Map<String, Object?>>[],
        );
        for (final Map<String, Object?> row
            in snapshot.before[table] ?? const <Map<String, Object?>>[]) {
          final int previousRev = (after[row['id']]?['rev'] as int?) ?? 0;
          final int restoredRev = (row['rev'] as int?) ?? 0;
          await db.customStatement(
            'UPDATE $table SET updated_at = ?, updated_by_device = ?, rev = ? WHERE id = ?',
            <Object?>[
              at.millisecondsSinceEpoch ~/ 1000,
              deviceId,
              (previousRev > restoredRev ? previousRev : restoredRev) + 1,
              row['id'],
            ],
          );
        }
      }
    }
  }
}

/// Plain row values passed through the isolate boundary.
typedef SnapshotRows = Map<String, List<Map<String, Object?>>>;

/// Only changed rows are retained in a committed snapshot.
typedef MergeSnapshot = ({
  String projectId,
  SnapshotRows before,
  SnapshotRows after,
  List<String> importedFiles,
});

Uint8List _encode(MergeSnapshot snapshot) {
  final SnapshotRows before = <String, List<Map<String, Object?>>>{};
  final SnapshotRows after = <String, List<Map<String, Object?>>>{};
  for (final String table in <String>{
    ...snapshot.before.keys,
    ...snapshot.after.keys,
  }) {
    final Map<String, Map<String, Object?>> oldRows = _indexed(
      snapshot.before[table] ?? const <Map<String, Object?>>[],
    );
    final Map<String, Map<String, Object?>> newRows = _indexed(
      snapshot.after[table] ?? const <Map<String, Object?>>[],
    );
    final Set<String> changed = <String>{
      for (final String id in <String>{...oldRows.keys, ...newRows.keys})
        if (!_equal(oldRows[id], newRows[id])) id,
    };
    if (changed.isEmpty) {
      continue;
    }
    before[table] = <Map<String, Object?>>[
      for (final String id in changed)
        if (oldRows[id] != null) oldRows[id]!,
    ];
    after[table] = <Map<String, Object?>>[
      for (final String id in changed)
        if (newRows[id] != null) newRows[id]!,
    ];
  }
  return Uint8List.fromList(
    utf8.encode(
      jsonEncode(<String, Object?>{
        'version': 1,
        'project_id': snapshot.projectId,
        'before': before,
        'after': after,
        'files': snapshot.importedFiles,
      }),
    ),
  );
}

MergeSnapshot _decode(Uint8List bytes) {
  final Object? decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map<String, Object?> ||
      decoded['version'] != 1 ||
      decoded['project_id'] is! String) {
    throw const CorruptionFailure();
  }
  SnapshotRows rows(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const CorruptionFailure();
    }
    final SnapshotRows parsed = <String, List<Map<String, Object?>>>{};
    for (final MapEntry<String, Object?> table in value.entries) {
      if ((!BundleFormat.insertOrder.contains(table.key) ||
              table.key == 'audit_log') &&
          table.key != 'merge_conflicts' &&
          table.key != 'version_vectors') {
        throw const CorruptionFailure();
      }
      if (table.value is! List<Object?>) {
        throw const CorruptionFailure();
      }
      parsed[table.key] = <Map<String, Object?>>[
        for (final Object? row in table.value! as List<Object?>)
          if (row is Map<String, Object?> && row['id'] is String)
            row
          else
            throw const CorruptionFailure(),
      ];
    }
    return parsed;
  }

  final Object? paths = decoded['files'];
  if (paths is! List<Object?> || paths.any((Object? path) => path is! String)) {
    throw const CorruptionFailure();
  }
  final SnapshotRows before = rows(decoded['before']);
  final SnapshotRows after = rows(decoded['after']);
  if (before.keys.toSet().difference(after.keys.toSet()).isNotEmpty ||
      after.keys.toSet().difference(before.keys.toSet()).isNotEmpty) {
    throw const CorruptionFailure();
  }
  return (
    projectId: decoded['project_id']! as String,
    before: before,
    after: after,
    importedFiles: <String>[for (final Object? path in paths) path! as String],
  );
}

Map<String, Map<String, Object?>> _indexed(List<Map<String, Object?>> rows) =>
    <String, Map<String, Object?>>{
      for (final Map<String, Object?> row in rows) row['id']! as String: row,
    };

bool _equal(Map<String, Object?>? left, Map<String, Object?>? right) =>
    left == null || right == null
    ? left == right
    : left.length == right.length &&
          left.entries.every(
            (MapEntry<String, Object?> entry) =>
                right[entry.key] == entry.value,
          );

Iterable<List<String>> _chunks(List<String> ids) sync* {
  const int size = 500;
  for (var start = 0; start < ids.length; start += size) {
    yield ids.sublist(
      start,
      start + size > ids.length ? ids.length : start + size,
    );
  }
}

T _valueOf<T>(Result<T> result) => switch (result) {
  Success<T>(:final value) => value,
  FailureResult<T>(failure: final Failure snapshotFailure) =>
    throw snapshotFailure,
};
