import 'package:drift/drift.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import 'app_database.dart';
import 'tables/tombstones.dart';
import 'transactions.dart';

/// Typed reads, watched lists and [Result] writes every table DAO extends.
///
/// Updates go through [_stampUpdate] so `rev` and `updatedAt` always move;
/// a write that bypasses this class leaves `rev` unchanged. [softDelete]
/// never issues a SQL DELETE; [recordTombstone] is the hook task 051 fills.
abstract class BaseDao<T extends Table, R> {
  /// Opens against [db] and [table], stamping writes from [clock],
  /// [deviceId] and [ids].
  BaseDao(
    this.db, {
    required this.table,
    required this.clock,
    required this.deviceId,
    required this.ids,
  });

  /// The database this DAO reads and writes.
  final GeneratedDatabase db;

  /// The generated table this DAO is bound to.
  final TableInfo<T, R> table;

  /// Clock used to stamp `createdAt` and `updatedAt`.
  final Clock clock;

  /// Device identity written into `updatedByDevice`.
  final String deviceId;

  /// Identifier service used when an insert omits `id`.
  final IdService ids;

  /// Live rows, newest watch after every write (FE-STATE-08).
  Stream<List<R>> watchAll() {
    return db.select(table).watch();
  }

  /// One row by merge id, or null when it is not there.
  Future<Result<R?>> getById(String id) {
    return _guard(() => _load(id));
  }

  /// Inserts or updates [row], stamping device, time and revision.
  Future<Result<R>> upsert(Insertable<R> row) {
    return _guard(() => _upsert(row));
  }

  /// Marks [id] deleted without removing the row. [reason] is required so a
  /// later tombstone can explain the write.
  Future<Result<void>> softDelete(String id, {required String reason}) {
    return _guard(() => _softDelete(id, reason: reason));
  }

  /// A slice of rows for virtualised lists (FE-PERF-03).
  Future<Result<List<R>>> page({required int offset, required int limit}) {
    return _guard(() {
      return (db.select(table)
            ..orderBy(<OrderClauseGenerator<T>>[
              (T tbl) => OrderingTerm.asc(_idColumn),
            ])
            ..limit(limit, offset: offset))
          .get();
    });
  }

  /// Writes a tombstone for [id] in the same transaction as the caller.
  ///
  /// The entity row is left in place; this never issues a SQL DELETE.
  Future<void> recordTombstone({
    required String id,
    required String reason,
  }) async {
    if (id.isEmpty) {
      throw const StorageFailure(
        message: 'That row is no longer on this device.',
        recoveryAction: 'Refresh the list and try again.',
      );
    }
    if (reason.isEmpty) {
      throw const StorageFailure(
        message: 'A delete needs a reason.',
        recoveryAction: 'Say why this row should be removed, then try again.',
      );
    }
    final GeneratedDatabase database = db;
    if (database is! AppDatabase) {
      return;
    }
    await writeTombstone(
      database,
      entityType: table.actualTableName,
      entityId: id,
      reason: reason,
      clock: clock,
      deviceId: deviceId,
    );
  }

  Future<R> _upsert(Insertable<R> row) async {
    final String id = _idOf(row) ?? ids.newId();
    final R? existing = await _load(id);
    final DateTime now = clock.nowUtc();
    if (existing == null) {
      await db.into(table).insert(_stampInsert(row, id: id, now: now));
    } else {
      final int rev = await _revOf(id);
      await (db.update(table)..where((T tbl) => _idColumn.equals(id))).write(
        _stampUpdate(row, now: now, rev: rev + 1),
      );
    }
    final R? written = await _load(id);
    if (written == null) {
      throw const StorageFailure(
        message: 'The database could not complete that write.',
        recoveryAction: 'Free up space or export a project, then try again.',
      );
    }
    return written;
  }

  Future<void> _softDelete(String id, {required String reason}) {
    return db.transaction(() async {
      final R? existing = await _load(id);
      if (existing == null) {
        throw const StorageFailure(
          message: 'That row is no longer on this device.',
          recoveryAction: 'Refresh the list and try again.',
        );
      }
      await recordTombstone(id: id, reason: reason);
    });
  }

  Future<R?> _load(String id) {
    return (db.select(
      table,
    )..where((T tbl) => _idColumn.equals(id))).getSingleOrNull();
  }

  Future<int> _revOf(String id) async {
    final QueryRow row = await db
        .customSelect(
          'SELECT rev FROM ${table.actualTableName} WHERE id = ?',
          variables: <Variable<String>>[Variable<String>(id)],
          readsFrom: <TableInfo<T, R>>{table},
        )
        .getSingle();
    return row.read<int>('rev');
  }

  Insertable<R> _stampInsert(
    Insertable<R> row, {
    required String id,
    required DateTime now,
  }) {
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false));
    columns['id'] = Variable<String>(id);
    columns.putIfAbsent('created_at', () => Variable<DateTime>(now));
    columns['updated_at'] = Variable<DateTime>(now);
    columns['updated_by_device'] = Variable<String>(deviceId);
    columns.putIfAbsent('rev', () => const Variable<int>(1));
    return RawValuesInsertable<R>(columns);
  }

  Insertable<R> _stampUpdate(
    Insertable<R> row, {
    required DateTime now,
    required int rev,
  }) {
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false));
    columns.remove('id');
    columns.remove('created_at');
    columns['updated_at'] = Variable<DateTime>(now);
    columns['updated_by_device'] = Variable<String>(deviceId);
    columns['rev'] = Variable<int>(rev);
    return RawValuesInsertable<R>(columns);
  }

  String? _idOf(Insertable<R> row) {
    final Expression<Object>? expression = row.toColumns(false)['id'];
    if (expression is Variable<String>) {
      return expression.value;
    }
    return null;
  }

  GeneratedColumn<String> get _idColumn {
    final GeneratedColumn<Object>? column = table.columnsByName['id'];
    if (column is GeneratedColumn<String>) {
      return column;
    }
    throw const StorageFailure(
      message: 'The database could not complete that write.',
      recoveryAction: 'Free up space or export a project, then try again.',
    );
  }

  Future<Result<S>> _guard<S>(Future<S> Function() body) async {
    try {
      return Success<S>(await body());
    } on Failure catch (failure) {
      return FailureResult<S>(failure);
    } on Object catch (error) {
      return FailureResult<S>(storageFailureFrom(error));
    }
  }
}
