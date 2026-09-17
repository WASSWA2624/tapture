import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/tables/sync_state.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

part 'merge_conflicts.dart';

/// A bundle-import session. Enough state to undo: counts, source and the
/// snapshot path.
@DataClassName('MergeSession')
class Merge extends Table with MergeColumns {
  @override
  String get tableName => 'merge_sessions';

  /// Bundle file name, stored as data.
  TextColumn get bundleName => text()();

  /// Device the bundle came from.
  TextColumn get sourceDevice => text()();

  /// When the bundle was imported.
  DateTimeColumn get importedAt => dateTime()();

  /// Per-category counts JSON. An object, stored as text.
  TextColumn get counts => text()();

  /// imported, undone or failed, stored as text.
  TextColumn get status => text()();

  /// Path of the pre-apply snapshot used by undo.
  TextColumn get undoSnapshotPath => text()();
}

/// Inserts a merge session. [MergeSession.counts] must be a JSON object.
Future<Result<MergeSession>> insertMergeSession(
  GeneratedDatabase db, {
  required Insertable<MergeSession> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    _ensureCountsJson(row);
    final AppDatabase database = db as AppDatabase;
    return _MergeDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    ).upsert(row);
  } on Failure catch (failure) {
    return FailureResult<MergeSession>(failure);
  } on Object catch (error) {
    return FailureResult<MergeSession>(storageFailureFrom(error));
  }
}

void _ensureCountsJson(Insertable<MergeSession> row) {
  final Expression<Object>? expression = row.toColumns(false)['counts'];
  if (expression is! Variable<String>) {
    return;
  }
  final String? raw = expression.value;
  if (raw == null) {
    return;
  }
  late final Object? decoded;
  try {
    decoded = jsonDecode(raw) as Object?;
  } on FormatException {
    throw const StorageFailure(
      message: 'Merge counts are not valid JSON.',
      recoveryAction: 'Fix the counts object and save again.',
    );
  }
  if (decoded is! Map) {
    throw const StorageFailure(
      message: 'Merge counts must be a JSON object.',
      recoveryAction: 'Fix the counts object and save again.',
    );
  }
}

final class _MergeDao extends BaseDao<Merge, MergeSession> {
  _MergeDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.merge);
}
