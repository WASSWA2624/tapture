part of 'merge.dart';

/// One per-field conflict a person must resolve. Index on [sessionId] plus
/// [resolution] serves the unresolved queue.
///
/// [mineValue] and [theirsValue] are stored verbatim. Merge never writes
/// [resolution]; a person does.
@TableIndex(
  name: 'merge_conflicts_by_session_resolution',
  columns: {#sessionId, #resolution},
)
@DataClassName('MergeConflict')
class MergeConflicts extends Table with MergeColumns {
  /// Session that produced this conflict.
  TextColumn get sessionId => text()();

  /// Table the entity belongs to.
  TextColumn get entityType => text()();

  /// Merge id of the entity.
  TextColumn get entityId => text()();

  /// Field that differs.
  TextColumn get fieldKey => text()();

  /// Local value as stored, never normalised.
  TextColumn get mineValue => text()();

  /// Incoming value as stored, never normalised.
  TextColumn get theirsValue => text()();

  /// Local provenance JSON. An object, stored as text.
  TextColumn get mineMeta => text()();

  /// Incoming provenance JSON. An object, stored as text.
  TextColumn get theirsMeta => text()();

  /// Human choice. Null until a person resolves it.
  TextColumn get resolution => text().nullable()();

  /// When it was resolved.
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  /// Operator who resolved it.
  TextColumn get resolvedBy => text().nullable()();
}

/// Inserts a conflict. Detection never writes [MergeConflict.resolution].
Future<Result<MergeConflict>> insertMergeConflict(
  GeneratedDatabase db, {
  required Insertable<MergeConflict> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false));
    columns.remove('resolution');
    columns.remove('resolved_at');
    columns.remove('resolved_by');
    final AppDatabase database = db as AppDatabase;
    return _MergeConflictsDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    ).upsert(RawValuesInsertable<MergeConflict>(columns));
  } on Failure catch (failure) {
    return FailureResult<MergeConflict>(failure);
  } on Object catch (error) {
    return FailureResult<MergeConflict>(storageFailureFrom(error));
  }
}

/// Unresolved conflicts for [sessionId], oldest first.
///
/// The `WHERE session_id AND resolution IS NULL` shape is what
/// `merge_conflicts_by_session_resolution` was created to serve.
Future<Result<List<MergeConflict>>> listUnresolvedMergeConflicts(
  GeneratedDatabase db, {
  required String sessionId,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<MergeConflict> rows =
        await (database.select(database.mergeConflicts)
              ..where(
                ($MergeConflictsTable tbl) =>
                    tbl.sessionId.equals(sessionId) & tbl.resolution.isNull(),
              )
              ..orderBy(<OrderClauseGenerator<$MergeConflictsTable>>[
                ($MergeConflictsTable tbl) => OrderingTerm.asc(tbl.createdAt),
                ($MergeConflictsTable tbl) => OrderingTerm.asc(tbl.id),
              ]))
            .get();
    return Success<List<MergeConflict>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<MergeConflict>>(failure);
  } on Object catch (error) {
    return FailureResult<List<MergeConflict>>(storageFailureFrom(error));
  }
}

/// Records a person's choice and bumps this device's vector entry for the
/// entity. Merge never picks a winner for a concurrent pair.
Future<Result<MergeConflict>> resolveMergeConflict(
  GeneratedDatabase db, {
  required String id,
  required String resolution,
  required String resolvedBy,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    if (resolution.isEmpty || resolvedBy.isEmpty) {
      throw const StorageFailure(
        message: 'A conflict needs a choice and an operator.',
        recoveryAction: 'Choose a side, then resolve again.',
      );
    }
    final AppDatabase database = db as AppDatabase;
    return runInTransaction(database, () async {
      final MergeConflict? existing =
          await (database.select(database.mergeConflicts)
                ..where(($MergeConflictsTable tbl) => tbl.id.equals(id)))
              .getSingleOrNull();
      if (existing == null) {
        throw const StorageFailure(
          message: 'That conflict is no longer on this device.',
          recoveryAction: 'Refresh the list and try again.',
        );
      }
      final Result<MergeConflict> written =
          await _MergeConflictsDao(
            database,
            clock: clock,
            deviceId: deviceId,
            ids: ids,
          ).upsert(
            MergeConflictsCompanion(
              id: Value<String>(id),
              resolution: Value<String>(resolution),
              resolvedBy: Value<String>(resolvedBy),
              resolvedAt: Value<DateTime>(clock.nowUtc()),
            ),
          );
      final MergeConflict conflict = switch (written) {
        Success<MergeConflict>(:final MergeConflict value) => value,
        FailureResult<MergeConflict>(:final Failure failure) => throw failure,
      };
      final Result<VersionVectorRow> bumped = await bumpVersionVector(
        database,
        entityType: conflict.entityType,
        entityId: conflict.entityId,
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      );
      switch (bumped) {
        case FailureResult<VersionVectorRow>(:final Failure failure):
          throw failure;
        case Success<VersionVectorRow>():
          return conflict;
      }
    });
  } on Failure catch (failure) {
    return FailureResult<MergeConflict>(failure);
  } on Object catch (error) {
    return FailureResult<MergeConflict>(storageFailureFrom(error));
  }
}

final class _MergeConflictsDao extends BaseDao<MergeConflicts, MergeConflict> {
  _MergeConflictsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.mergeConflicts);
}
