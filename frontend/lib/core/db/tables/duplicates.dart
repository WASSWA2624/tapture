import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// A detected duplicate pair. Unique on the ordered record ids so one pair
/// is never queued twice, regardless of argument order.
///
/// Detection writes [signal] and [score] only. A person writes [resolution].
@TableIndex(
  name: 'duplicates_by_pair',
  columns: {#leftRecordId, #rightRecordId},
  unique: true,
)
@TableIndex(
  name: 'duplicates_by_project_status',
  columns: {#projectId, #status},
)
@DataClassName('DuplicatePair')
class Duplicates extends Table with MergeColumns {
  /// Project both records belong to.
  TextColumn get projectId => text()();

  /// Lower record id of the ordered pair.
  TextColumn get leftRecordId => text()();

  /// Higher record id of the ordered pair.
  TextColumn get rightRecordId => text()();

  /// Detection signal that ranked this pair, stored as data.
  TextColumn get signal => text()();

  /// Combined score from detection. A proposal, never a decision.
  RealColumn get score => real()();

  /// unresolved or resolved. The review list filters on this column.
  TextColumn get status => textEnum<DuplicatePairStatus>()();

  /// Human choice. Null until a person resolves the pair.
  TextColumn get resolution => text().nullable()();

  /// Operator who resolved it.
  TextColumn get resolvedBy => text().nullable()();

  /// When it was resolved.
  DateTimeColumn get resolvedAt => dateTime().nullable()();
}

/// Queue state of a [DuplicatePair].
enum DuplicatePairStatus {
  /// Waiting for a person to choose.
  unresolved,

  /// A person has recorded a [DuplicatePair.resolution].
  resolved,
}

/// Inserts a detected pair, or updates signal and score on the existing row.
///
/// [leftRecordId] and [rightRecordId] are ordered before write. Detection
/// never writes [DuplicatePair.resolution].
Future<Result<DuplicatePair>> upsertDetectedDuplicate(
  GeneratedDatabase db, {
  required Insertable<DuplicatePair> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false));
    final String? a = _stringExpression(columns['left_record_id']);
    final String? b = _stringExpression(columns['right_record_id']);
    if (a == null || b == null) {
      throw const StorageFailure(
        message: 'A duplicate pair needs two records.',
        recoveryAction: 'Choose both records and try again.',
      );
    }
    if (a == b) {
      throw const StorageFailure(
        message: 'A record cannot be a duplicate of itself.',
        recoveryAction: 'Choose two different records and try again.',
      );
    }
    final ({String left, String right}) ordered = _orderedPair(a, b);
    final DuplicatePair? existing = await _pairOf(
      database,
      leftRecordId: ordered.left,
      rightRecordId: ordered.right,
    );
    final String? projectId = _stringExpression(columns['project_id']);
    final String? signal = _stringExpression(columns['signal']);
    final double? score = _doubleExpression(columns['score']);
    final DuplicatesCompanion companion;
    if (existing != null) {
      companion = DuplicatesCompanion(
        id: Value<String>(existing.id),
        signal: signal == null
            ? const Value<String>.absent()
            : Value<String>(signal),
        score: score == null
            ? const Value<double>.absent()
            : Value<double>(score),
      );
    } else {
      if (projectId == null || signal == null || score == null) {
        throw const StorageFailure(
          message: 'A duplicate pair needs a project, a signal and a score.',
          recoveryAction: 'Run detection again, then try again.',
        );
      }
      companion = DuplicatesCompanion(
        projectId: Value<String>(projectId),
        leftRecordId: Value<String>(ordered.left),
        rightRecordId: Value<String>(ordered.right),
        signal: Value<String>(signal),
        score: Value<double>(score),
        status: const Value<DuplicatePairStatus>(
          DuplicatePairStatus.unresolved,
        ),
      );
    }
    return _DuplicatesDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    ).upsert(companion);
  } on Failure catch (failure) {
    return FailureResult<DuplicatePair>(failure);
  } on Object catch (error) {
    return FailureResult<DuplicatePair>(storageFailureFrom(error));
  }
}

/// Records a person's choice. Source records are left intact.
Future<Result<DuplicatePair>> resolveDuplicate(
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
        message: 'A resolution needs a choice and an operator.',
        recoveryAction: 'Choose how to resolve the pair, then try again.',
      );
    }
    final AppDatabase database = db as AppDatabase;
    final DuplicatePair? existing = await (database.select(
      database.duplicates,
    )..where(($DuplicatesTable tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw const StorageFailure(
        message: 'That pair is no longer on this device.',
        recoveryAction: 'Refresh the list and try again.',
      );
    }
    return _DuplicatesDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    ).upsert(
      DuplicatesCompanion(
        id: Value<String>(id),
        status: const Value<DuplicatePairStatus>(DuplicatePairStatus.resolved),
        resolution: Value<String>(resolution),
        resolvedBy: Value<String>(resolvedBy),
        resolvedAt: Value<DateTime>(clock.nowUtc()),
      ),
    );
  } on Failure catch (failure) {
    return FailureResult<DuplicatePair>(failure);
  } on Object catch (error) {
    return FailureResult<DuplicatePair>(storageFailureFrom(error));
  }
}

/// A page of pairs in [projectId] with [status], oldest first.
///
/// The `WHERE project_id AND status` shape is what
/// `duplicates_by_project_status` was created to serve.
Future<Result<List<DuplicatePair>>> listDuplicatesByProjectAndStatus(
  GeneratedDatabase db, {
  required String projectId,
  required DuplicatePairStatus status,
  required int offset,
  required int limit,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<DuplicatePair> rows =
        await (database.select(database.duplicates)
              ..where(
                ($DuplicatesTable tbl) =>
                    tbl.projectId.equals(projectId) &
                    tbl.status.equalsValue(status),
              )
              ..orderBy(<OrderClauseGenerator<$DuplicatesTable>>[
                ($DuplicatesTable tbl) => OrderingTerm.asc(tbl.createdAt),
                ($DuplicatesTable tbl) => OrderingTerm.asc(tbl.id),
              ])
              ..limit(limit, offset: offset))
            .get();
    return Success<List<DuplicatePair>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<DuplicatePair>>(failure);
  } on Object catch (error) {
    return FailureResult<List<DuplicatePair>>(storageFailureFrom(error));
  }
}

({String left, String right}) _orderedPair(String a, String b) {
  if (a.compareTo(b) <= 0) {
    return (left: a, right: b);
  }
  return (left: b, right: a);
}

Future<DuplicatePair?> _pairOf(
  AppDatabase db, {
  required String leftRecordId,
  required String rightRecordId,
}) {
  return (db.select(db.duplicates)..where(
        ($DuplicatesTable tbl) =>
            tbl.leftRecordId.equals(leftRecordId) &
            tbl.rightRecordId.equals(rightRecordId),
      ))
      .getSingleOrNull();
}

String? _stringExpression(Expression<Object>? expression) {
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

double? _doubleExpression(Expression<Object>? expression) {
  if (expression is Variable<double>) {
    return expression.value;
  }
  return null;
}

final class _DuplicatesDao extends BaseDao<Duplicates, DuplicatePair> {
  _DuplicatesDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.duplicates);
}
