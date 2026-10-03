import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/merge.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/merge_history_entry.dart';
import '../domain/merge_repository.dart';
import 'merge_snapshot_store.dart';
import 'package_files.dart';
import 'package_import_repository_impl.dart';

/// Persistent merge history and durable snapshot undo on native and web stores.
final class MergeRepositoryImpl implements MergeRepository {
  /// Shares the importer's database, evidence store and provenance.
  const MergeRepositoryImpl({
    required this.db,
    required this.files,
    required this.clock,
    required this.deviceId,
  });

  /// Database that owns the project's durable merge history.
  final sqlite.AppDatabase db;

  /// Platform file boundary used for retained snapshots and recycled evidence.
  final PackageFiles files;

  /// Supplies the retention deadline and undo timestamp.
  final Clock clock;

  /// Replica performing the restore.
  final String deviceId;

  /// Reconciles file moves interrupted before SQLite committed an undo.
  /// Run before exposing project files on launch. Recovery is idempotent and
  /// reports storage failures as values, retaining its journal for retry.
  Future<Result<void>> recoverInterruptedUndo() async {
    try {
      final List<sqlite.MergeSession> sessions = await db
          .customSelect(
            'SELECT * FROM merge_sessions WHERE $mergePendingUndoWhere',
            readsFrom: <ResultSetImplementation<dynamic, dynamic>>{db.merge},
          )
          .asyncMap(db.merge.mapFromRow)
          .get();
      for (final sqlite.MergeSession session in sessions) {
        final String journal =
            _object(session.counts)['undo_journal']! as String;
        if (!await files.exists(journal)) {
          await _clearUndoIntent(session.id);
          continue;
        }
        if (session.status == 'applied') {
          final String retained = '.recycle/merge-${session.id}/snapshot.json';
          if (!await files.exists(session.undoSnapshotPath) &&
              await files.exists(retained)) {
            await files.move(retained, session.undoSnapshotPath);
          }
          final MergeSnapshot snapshot = await MergeSnapshotStore(
            db,
            files,
          ).read(session.undoSnapshotPath);
          for (final String original in snapshot.importedFiles) {
            final String recycled = '.recycle/merge-${session.id}/$original';
            if (!await files.exists(original) && await files.exists(recycled)) {
              await files.move(recycled, original);
            }
          }
        }
        await files.remove(journal);
        await _clearUndoIntent(session.id);
      }
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        error is Failure ? error : storageFailureFrom(error),
      );
    }
  }

  @override
  Stream<List<MergeHistoryEntry>> watchHistory(String projectId) {
    return db
        .customSelect(
          "SELECT m.*, COALESCE(c.resolutions, '{}') AS resolution_counts "
          'FROM merge_sessions m LEFT JOIN ('
          'SELECT session_id, json_group_object(choice, n) AS resolutions FROM ('
          "SELECT session_id, COALESCE(resolution, 'later') AS choice, COUNT(*) AS n "
          'FROM merge_conflicts GROUP BY session_id, resolution) GROUP BY session_id'
          ") c ON c.session_id = m.id WHERE json_extract(m.counts, '\$.project_id') = ? "
          'ORDER BY m.imported_at DESC, m.id DESC',
          variables: <Variable<Object>>[Variable<String>(projectId)],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            db.merge,
            db.mergeConflicts,
          },
        )
        .watch()
        .asyncMap((List<QueryRow> rows) async {
          final List<MergeHistoryEntry> entries = <MergeHistoryEntry>[];
          for (final QueryRow row in rows) {
            final String id = row.read<String>('id');
            final Map<String, Object?> counts = _object(
              row.read<String>('counts'),
            );
            final Map<String, Object?> resolutions = _object(
              row.read<String>('resolution_counts'),
            );
            final DateTime at = DateTime.fromMillisecondsSinceEpoch(
              row.read<int>('imported_at') * 1000,
              isUtc: true,
            );
            final DateTime until = at.add(AppConstants.retention.duration);
            final String path = row.read<String>('undo_snapshot_path');
            final bool available =
                row.read<String>('status') == 'applied' &&
                clock.nowUtc().isBefore(until) &&
                path.isNotEmpty &&
                await files.exists(path);
            entries.add(
              MergeHistoryEntry(
                id: id,
                projectId: projectId,
                bundleId: '${counts['bundle_id'] ?? ''}',
                bundleName: row.read<String>('bundle_name'),
                sourceDevice: row.read<String>('source_device'),
                at: at,
                status: row.read<String>('status'),
                counts: <String, int>{
                  for (final MapEntry<String, Object?> count in counts.entries)
                    if (count.value is int) count.key: count.value! as int,
                },
                resolutions: <String, int>{
                  for (final MapEntry<String, Object?> choice
                      in resolutions.entries)
                    choice.key: choice.value! as int,
                },
                undoUntil: available ? until : null,
              ),
            );
          }
          return entries;
        });
  }

  @override
  Future<Result<void>> undo(String id) async {
    final List<({String from, String to})> moved =
        <({String from, String to})>[];
    String? journal;
    try {
      final sqlite.MergeSession? session =
          await (db.select(db.merge)
                ..where((sqlite.$MergeTable row) => row.id.equals(id)))
              .getSingleOrNull();
      if (session == null ||
          session.status != 'applied' ||
          session.undoSnapshotPath.isEmpty ||
          !clock.nowUtc().isBefore(
            session.importedAt.add(AppConstants.retention.duration),
          )) {
        throw _undoUnavailableFailure;
      }
      final MergeSnapshotStore store = MergeSnapshotStore(db, files);
      final MergeSnapshot snapshot = await store.read(session.undoSnapshotPath);
      final QueryRow? newer = await db
          .customSelect(
            "SELECT 1 FROM merge_sessions WHERE json_extract(counts, '\$.project_id') = ? "
            "AND status = 'applied' AND (imported_at > ? OR (imported_at = ? AND id > ?)) LIMIT 1",
            variables: <Variable<Object>>[
              Variable<String>(snapshot.projectId),
              Variable<int>(session.importedAt.millisecondsSinceEpoch ~/ 1000),
              Variable<int>(session.importedAt.millisecondsSinceEpoch ~/ 1000),
              Variable<String>(id),
            ],
          )
          .getSingleOrNull();
      if (newer != null) {
        throw ValidationFailure(
          localizedMessage: Copy.messages.mergeUndoChanged,
          localizedRecovery: Copy.messages.mergeUndoChangedRecovery,
        );
      }
      await store.ensureUnchanged(snapshot);
      journal = '${session.undoSnapshotPath}.undo';
      // Publish intent before the journal or any file move. Recovery reads only
      // these indexed rows, including a kill before journal creation completes.
      await db.customStatement(
        "UPDATE merge_sessions SET counts = json_set(counts, '\$.undo_journal', ?) WHERE id = ?",
        <Object?>[journal, id],
      );
      final written = await files.write(journal, Uint8List(0));
      if (written case FailureResult(failure: final Failure writeFailure)) {
        throw writeFailure;
      }
      final Result<void> restored = await runInTransaction(
        db,
        () => RecordSchema.deferIndexing(db, () async {
          await store.ensureUnchanged(snapshot);
          for (final String path in snapshot.importedFiles) {
            if (await files.exists(path)) {
              final String landing = '.recycle/merge-$id/$path';
              await files.move(path, landing);
              moved.add((from: path, to: landing));
            }
          }
          await store.restore(snapshot, at: clock.nowUtc(), deviceId: deviceId);
          final String retained = '.recycle/merge-$id/snapshot.json';
          await files.move(session.undoSnapshotPath, retained);
          moved.add((from: session.undoSnapshotPath, to: retained));
          await db.customStatement(
            "UPDATE merge_sessions SET status = 'undone', undo_snapshot_path = ?, counts = json_set(counts, '\$.undo_journal', ?), updated_at = ?, updated_by_device = ?, rev = rev + 1 WHERE id = ?",
            <Object?>[
              retained,
              journal,
              clock.nowUtc().millisecondsSinceEpoch ~/ 1000,
              deviceId,
              id,
            ],
          );
          await appendAudit(
            db,
            entityType: 'projects',
            entityId: snapshot.projectId,
            action: AuditAction.updated,
            fieldKey: 'merge_undo',
            previousValue: id,
            newValue: 'undone',
            reason: session.bundleName,
            clock: clock,
            device: deviceId,
          );
        }),
      );
      if (restored case FailureResult<void>(
        failure: final Failure restoreFailure,
      )) {
        throw restoreFailure;
      }
      try {
        await files.remove(journal);
        await _clearUndoIntent(id);
      } on Object {
        // SQLite committed; recovery only cleans this completed journal.
      }
      journal = null;
      return const Success<void>(null);
    } on Object catch (error) {
      try {
        for (final file in moved.reversed) {
          await files.move(file.to, file.from);
        }
        if (journal != null) {
          await files.remove(journal);
          await _clearUndoIntent(id);
        }
      } on Object {
        // Keep the durable journal: bootstrap recovery completes these moves.
      }
      return FailureResult<void>(
        error is Failure ? error : storageFailureFrom(error),
      );
    }
  }

  Future<void> _clearUndoIntent(String id) => db.customStatement(
    "UPDATE merge_sessions SET counts = json_remove(counts, '\$.undo_journal') WHERE id = ?",
    <Object?>[id],
  );

  @override
  Stream<List<MergeSession>> watchAll() => db
      .customSelect(
        'SELECT id, bundle_name, status FROM merge_sessions ORDER BY imported_at DESC, id DESC',
        readsFrom: <ResultSetImplementation<dynamic, dynamic>>{db.merge},
      )
      .watch()
      .map(
        (List<QueryRow> rows) => <MergeSession>[
          for (final QueryRow row in rows) _session(row),
        ],
      );

  @override
  Future<Result<MergeSession?>> byId(String id) async {
    try {
      final QueryRow? row = await db
          .customSelect(
            'SELECT id, bundle_name, status FROM merge_sessions WHERE id = ?',
            variables: <Variable<Object>>[Variable<String>(id)],
          )
          .getSingleOrNull();
      return Success<MergeSession?>(row == null ? null : _session(row));
    } on Object catch (error) {
      return FailureResult<MergeSession?>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<MergeSession>> save(MergeSession session) async {
    // Sessions are published only by the package transaction. This port can
    // rename existing history labels without inventing a completed merge.
    if (session.bundleName.trim().isEmpty) {
      return FailureResult<MergeSession>(
        ValidationFailure(
          localizedMessage: Copy.messages.importFileChanged,
          localizedRecovery: Copy.messages.importFailedRecovery,
        ),
      );
    }
    try {
      final int affected = await db.customUpdate(
        'UPDATE merge_sessions SET bundle_name = ? WHERE id = ?',
        variables: <Variable<Object>>[
          Variable<String>(session.bundleName),
          Variable<String>(session.id),
        ],
        updates: <TableInfo<Table, Object?>>{db.merge},
      );
      return affected == 0
          ? FailureResult<MergeSession>(_undoUnavailableFailure)
          : Success<MergeSession>(session);
    } on Object catch (error) {
      return FailureResult<MergeSession>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    // History and its audit must remain available; deleting a live session
    // would sever unresolved conflicts from their source.
    return FailureResult<void>(_undoUnavailableFailure);
  }
}

final StorageFailure _undoUnavailableFailure = StorageFailure(
  localizedMessage: Copy.messages.mergeUndoUnavailable,
  localizedRecovery: Copy.messages.importFailedRecovery,
);

MergeSession _session(QueryRow row) => (
  id: row.read<String>('id'),
  bundleName: row.read<String>('bundle_name'),
  status: row.read<String>('status'),
);

Map<String, Object?> _object(String raw) {
  final Object? decoded = jsonDecode(raw);
  return decoded is Map<String, Object?> ? decoded : const <String, Object?>{};
}

/// Uses the production importer's transaction and file store.
final Provider<MergeRepository?> mergeRepositoryProvider =
    Provider<MergeRepository?>((Ref ref) {
      final repository = ref.watch(packageImportRepositoryProvider);
      return repository is PackageImportRepositoryImpl
          ? repository.historyRepository
          : null;
    });
