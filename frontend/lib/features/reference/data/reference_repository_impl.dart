import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/reference.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/reference_repository.dart';
import 'reference_mapper.dart';

/// Drift-backed [ReferenceRepository]. The only feature file besides the
/// mapper that imports both the table and the domain.
final class ReferenceRepositoryImpl implements ReferenceRepository {
  /// Opens against [_db], stamping writes from [_clock], [_deviceId] and
  /// [_ids].
  ReferenceRepositoryImpl({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._ids,
  });

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;

  @override
  Stream<List<ReferenceDataset>> watchAll() {
    return _changes().asyncMap((_) => _listAll());
  }

  @override
  Stream<List<ReferenceDataset>> watchByProject(String projectId) {
    return _changes().asyncMap((_) => _listForProject(projectId));
  }

  @override
  Future<Result<ReferenceDataset?>> byId(String id) async {
    if (id.isEmpty) {
      return const Success<ReferenceDataset?>(null);
    }
    try {
      return Success<ReferenceDataset?>(await _load(id));
    } on Failure catch (failure) {
      return FailureResult<ReferenceDataset?>(failure);
    } on Object catch (error) {
      return FailureResult<ReferenceDataset?>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<ReferenceDataset>> save(ReferenceDataset dataset) async {
    final ValidationFailure? invalid = _validateDataset(dataset);
    if (invalid != null) {
      return FailureResult<ReferenceDataset>(invalid);
    }
    try {
      final Result<sqlite.ReferenceDatasetRow> written =
          await upsertReferenceDataset(
            _db,
            row: ReferenceMapper.datasetToRow(dataset),
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
          );
      return switch (written) {
        FailureResult<sqlite.ReferenceDatasetRow>(:final Failure failure) =>
          FailureResult<ReferenceDataset>(failure),
        Success<sqlite.ReferenceDatasetRow>(
          :final sqlite.ReferenceDatasetRow value,
        ) =>
          Success<ReferenceDataset>(ReferenceMapper.datasetFromRow(value)),
      };
    } on Failure catch (failure) {
      return FailureResult<ReferenceDataset>(failure);
    } on Object catch (error) {
      return FailureResult<ReferenceDataset>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<ReferenceDataset>> importDataset({
    required ReferenceDataset dataset,
    required List<ReferenceRow> rows,
  }) async {
    final ValidationFailure? invalid = _validateDataset(dataset);
    if (invalid != null) {
      return FailureResult<ReferenceDataset>(invalid);
    }
    if (!dataset.duplicatesAllowed) {
      final Set<String> seen = <String>{};
      for (final ReferenceRow row in rows) {
        if (!seen.add(row.key)) {
          return const FailureResult<ReferenceDataset>(
            ValidationFailure(
              message: 'That key column has duplicate values.',
              recoveryAction:
                  'Pick another key column, or confirm duplicates are expected.',
            ),
          );
        }
      }
    }
    try {
      final Result<sqlite.ReferenceDatasetRow> written =
          await importReferenceDataset(
            _db,
            dataset: ReferenceMapper.datasetToRow(
              dataset.copyWith(rowCount: rows.length),
            ),
            rows: <({String keyValue, Map<String, String> values})>[
              for (final ReferenceRow row in rows)
                (
                  keyValue: row.key,
                  values: ReferenceMapper.valuesForImport(row),
                ),
            ],
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
          );
      return switch (written) {
        FailureResult<sqlite.ReferenceDatasetRow>(:final Failure failure) =>
          FailureResult<ReferenceDataset>(failure),
        Success<sqlite.ReferenceDatasetRow>(
          :final sqlite.ReferenceDatasetRow value,
        ) =>
          Success<ReferenceDataset>(ReferenceMapper.datasetFromRow(value)),
      };
    } on Failure catch (failure) {
      return FailureResult<ReferenceDataset>(failure);
    } on Object catch (error) {
      return FailureResult<ReferenceDataset>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    if (id.isEmpty) {
      return const FailureResult<void>(_missing);
    }
    if (reason.trim().isEmpty) {
      return const FailureResult<void>(_needsReason);
    }
    return runInTransaction(_db, () async {
      final sqlite.ReferenceDatasetRow? header = await _header(id);
      if (header == null || await _isTombstoned(_db.reference, id)) {
        throw const StorageFailure(
          message: 'That row is no longer on this device.',
          recoveryAction: 'Refresh the list and try again.',
        );
      }
      final List<sqlite.ReferenceLookupRow> rows =
          await (_db.select(_db.referenceRows)..where(
                (sqlite.$ReferenceRowsTable tbl) => tbl.datasetId.equals(id),
              ))
              .get();
      for (final sqlite.ReferenceLookupRow row in rows) {
        await writeTombstone(
          _db,
          entityType: _db.referenceRows.actualTableName,
          entityId: row.id,
          reason: reason,
          clock: _clock,
          deviceId: _deviceId,
        );
      }
      await writeTombstone(
        _db,
        entityType: _db.reference.actualTableName,
        entityId: id,
        reason: reason,
        clock: _clock,
        deviceId: _deviceId,
      );
    });
  }

  @override
  Future<Result<List<ReferenceRow>>> pageRows({
    required String datasetId,
    required int offset,
    required int limit,
    String query = '',
  }) async {
    try {
      if (limit <= 0) {
        return const Success<List<ReferenceRow>>(<ReferenceRow>[]);
      }
      final String needle = query.trim().toLowerCase();
      final int start = offset < 0 ? 0 : offset;
      // SQLite's lower() folds ASCII letters only, so only an ASCII needle is
      // filtered and paged in SQLite. Any other needle keeps Dart's Unicode
      // case folding over bounded key-ordered pages. Either way only the
      // requested page crosses the repository boundary.
      return Success<List<ReferenceRow>>(
        _isAscii(needle)
            ? await _liveRows(
                datasetId,
                needle: needle,
                offset: start,
                limit: limit,
              )
            : await _scanRows(
                datasetId,
                needle: needle,
                offset: start,
                limit: limit,
              ),
      );
    } on Failure catch (failure) {
      return FailureResult<List<ReferenceRow>>(failure);
    } on Object catch (error) {
      return FailureResult<List<ReferenceRow>>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<ReferenceRow?>> rowById(String id) async {
    if (id.isEmpty) {
      return const Success<ReferenceRow?>(null);
    }
    try {
      final sqlite.ReferenceLookupRow? row =
          await (_db.select(_db.referenceRows)
                ..where((sqlite.$ReferenceRowsTable tbl) => tbl.id.equals(id)))
              .getSingleOrNull();
      if (row == null || await _isTombstoned(_db.referenceRows, id)) {
        return const Success<ReferenceRow?>(null);
      }
      return Success<ReferenceRow?>(ReferenceMapper.rowFromRow(row));
    } on Failure catch (failure) {
      return FailureResult<ReferenceRow?>(failure);
    } on Object catch (error) {
      return FailureResult<ReferenceRow?>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<ReferenceRow>> saveRow(
    ReferenceRow row, {
    Map<String, String>? previousValues,
  }) async {
    if (row.datasetId.isEmpty || row.key.trim().isEmpty) {
      return const FailureResult<ReferenceRow>(
        ValidationFailure(
          message: 'A row needs a dataset and a key.',
          recoveryAction: 'Fill those fields and save again.',
        ),
      );
    }
    return runInTransaction(_db, () async {
      final Result<sqlite.ReferenceLookupRow> written =
          await upsertReferenceRow(
            _db,
            row: ReferenceMapper.rowToRow(row),
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
          );
      final sqlite.ReferenceLookupRow stored = switch (written) {
        Success<sqlite.ReferenceLookupRow>(
          :final sqlite.ReferenceLookupRow value,
        ) =>
          value,
        FailureResult<sqlite.ReferenceLookupRow>(:final Failure failure) =>
          throw StorageFailure(
            message: failure.message,
            recoveryAction: failure.recoveryAction ?? 'Try again.',
          ),
      };
      if (previousValues != null) {
        for (final MapEntry<String, String> entry in row.values.entries) {
          final String? previous = previousValues[entry.key];
          if (previous == entry.value) {
            continue;
          }
          await appendAudit(
            _db,
            entityType: 'reference_row',
            entityId: stored.id,
            action: previous == null
                ? AuditAction.created
                : AuditAction.updated,
            fieldKey: entry.key,
            previousValue: previous,
            newValue: entry.value,
            clock: _clock,
            device: _deviceId,
          );
        }
      } else if (row.id.isEmpty || row.addedOnDevice) {
        await appendAudit(
          _db,
          entityType: 'reference_row',
          entityId: stored.id,
          action: AuditAction.created,
          fieldKey: 'key',
          newValue: row.key,
          clock: _clock,
          device: _deviceId,
        );
      }
      final int count = await _countLiveRows(row.datasetId);
      final ReferenceDataset? header = await _load(row.datasetId);
      if (header != null && header.rowCount != count) {
        await upsertReferenceDataset(
          _db,
          row: ReferenceMapper.datasetToRow(header.copyWith(rowCount: count)),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        );
      }
      return ReferenceMapper.rowFromRow(stored);
    });
  }

  @override
  Future<Result<ReferenceRow?>> lookupByKey({
    required String datasetId,
    required String keyValue,
  }) async {
    if (await _load(datasetId) == null) {
      return const Success<ReferenceRow?>(null);
    }
    final Result<sqlite.ReferenceLookupRow?> found =
        await lookupReferenceRowByKey(
          _db,
          datasetId: datasetId,
          keyValue: keyValue,
        );
    if (found case Success<sqlite.ReferenceLookupRow?>(
      :final sqlite.ReferenceLookupRow? value,
    )) {
      if (value != null && await _isTombstoned(_db.referenceRows, value.id)) {
        return const Success<ReferenceRow?>(null);
      }
    }
    return switch (found) {
      FailureResult<sqlite.ReferenceLookupRow?>(:final Failure failure) =>
        FailureResult<ReferenceRow?>(failure),
      Success<sqlite.ReferenceLookupRow?>(
        :final sqlite.ReferenceLookupRow? value,
      ) =>
        Success<ReferenceRow?>(
          value == null ? null : ReferenceMapper.rowFromRow(value),
        ),
    };
  }

  @override
  Future<Result<List<ReferenceRow>>> lookupByNormalised({
    required String datasetId,
    required String query,
  }) async {
    if (await _load(datasetId) == null) {
      return const Success<List<ReferenceRow>>(<ReferenceRow>[]);
    }
    final Result<List<sqlite.ReferenceLookupRow>> found =
        await lookupReferenceRowsByNormalised(
          _db,
          datasetId: datasetId,
          query: query,
        );
    final Set<String> dead = await _tombstoned(_db.referenceRows);
    return switch (found) {
      FailureResult<List<sqlite.ReferenceLookupRow>>(:final Failure failure) =>
        FailureResult<List<ReferenceRow>>(failure),
      Success<List<sqlite.ReferenceLookupRow>>(
        :final List<sqlite.ReferenceLookupRow> value,
      ) =>
        Success<List<ReferenceRow>>(<ReferenceRow>[
          for (final sqlite.ReferenceLookupRow row in value)
            if (!dead.contains(row.id)) ReferenceMapper.rowFromRow(row),
        ]),
    };
  }

  @override
  Future<Result<List<ReferenceRow>>> allRows(String datasetId) async {
    return pageRows(datasetId: datasetId, offset: 0, limit: 1 << 30);
  }

  Future<List<ReferenceDataset>> _listAll() async {
    final List<sqlite.ReferenceDatasetRow> headers = await _db
        .select(_db.reference)
        .get();
    final Set<String> dead = await _tombstoned(_db.reference);
    final List<ReferenceDataset> list = <ReferenceDataset>[
      for (final sqlite.ReferenceDatasetRow header in headers)
        if (!dead.contains(header.id)) ReferenceMapper.datasetFromRow(header),
    ];
    list.sort(_byName);
    return list;
  }

  Future<List<ReferenceDataset>> _listForProject(String projectId) async {
    final List<ReferenceDataset> all = await _listAll();
    return <ReferenceDataset>[
      for (final ReferenceDataset dataset in all)
        if (dataset.projectId == null ||
            dataset.projectId!.isEmpty ||
            dataset.projectId == projectId)
          dataset,
    ];
  }

  Future<ReferenceDataset?> _load(String id) async {
    final sqlite.ReferenceDatasetRow? header = await _header(id);
    if (header == null || await _isTombstoned(_db.reference, id)) {
      return null;
    }
    return ReferenceMapper.datasetFromRow(header);
  }

  Future<sqlite.ReferenceDatasetRow?> _header(String id) {
    return (_db.select(_db.reference)
          ..where((sqlite.$ReferenceTable tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> _countLiveRows(String datasetId) async {
    final List<sqlite.ReferenceLookupRow> rows =
        await (_db.select(_db.referenceRows)..where(
              (sqlite.$ReferenceRowsTable tbl) =>
                  tbl.datasetId.equals(datasetId),
            ))
            .get();
    final Set<String> dead = await _tombstoned(_db.referenceRows);
    return rows
        .where((sqlite.ReferenceLookupRow r) => !dead.contains(r.id))
        .length;
  }

  Stream<void> _changes() {
    return Stream<void>.multi((MultiStreamController<void> listener) {
      listener.add(null);
      final StreamSubscription<List<sqlite.ReferenceDatasetRow>> a = _db
          .select(_db.reference)
          .watch()
          .listen((_) => listener.add(null));
      final StreamSubscription<List<sqlite.ReferenceLookupRow>> b = _db
          .select(_db.referenceRows)
          .watch()
          .listen((_) => listener.add(null));
      listener.onCancel = () async {
        await a.cancel();
        await b.cancel();
      };
    });
  }

  Future<Set<String>> _tombstoned(TableInfo<Table, Object?> table) async {
    final List<sqlite.Tombstone> rows =
        await (_db.select(_db.tombstones)..where(
              (sqlite.$TombstonesTable tbl) =>
                  tbl.entityType.equals(table.actualTableName),
            ))
            .get();
    return <String>{for (final sqlite.Tombstone row in rows) row.entityId};
  }

  Future<bool> _isTombstoned(TableInfo<Table, Object?> table, String id) async {
    final sqlite.Tombstone? row =
        await (_db.select(_db.tombstones)..where(
              (sqlite.$TombstonesTable tbl) =>
                  tbl.entityType.equals(table.actualTableName) &
                  tbl.entityId.equals(id),
            ))
            .getSingleOrNull();
    return row != null;
  }

  /// Live rows of [datasetId] in key order, resuming just past [after].
  ///
  /// A non-empty [needle] keeps rows whose key or a visible value contains it
  /// after SQLite's ASCII case folding; the device marker is never searched.
  Future<List<ReferenceRow>> _liveRows(
    String datasetId, {
    required String needle,
    required int offset,
    required int limit,
    ReferenceRow? after,
  }) async {
    final List<QueryRow> page = await _db
        .customSelect(
          '''SELECT r.* FROM reference_rows r
WHERE r.dataset_id = ?
AND NOT EXISTS (SELECT 1 FROM tombstones t
  WHERE t.entity_type = 'reference_rows' AND t.entity_id = r.id)
AND (? = '' OR instr(lower(r.key_value), ?) > 0 OR EXISTS (
  SELECT 1 FROM json_each(r."values") cell
  WHERE cell.key <> ? AND instr(lower(CAST(cell.value AS TEXT)), ?) > 0))
AND (? IS NULL OR r.key_value > ? OR (r.key_value = ? AND r.id > ?))
ORDER BY r.key_value, r.id LIMIT ? OFFSET ?''',
          variables: <Variable<Object>>[
            Variable<String>(datasetId),
            Variable<String>(needle),
            Variable<String>(needle),
            const Variable<String>(ReferenceMapper.addedOnDeviceKey),
            Variable<String>(needle),
            Variable<String>(after?.id),
            Variable<String>(after?.key),
            Variable<String>(after?.key),
            Variable<String>(after?.id),
            Variable<int>(limit),
            Variable<int>(offset),
          ],
          readsFrom: <TableInfo<Table, Object?>>{
            _db.referenceRows,
            _db.tombstones,
          },
        )
        .get();
    return <ReferenceRow>[
      for (final QueryRow row in page)
        ReferenceMapper.rowFromRow(_db.referenceRows.map(row.data)),
    ];
  }

  /// Rows of [datasetId] whose key or a value contains [needle] under Dart's
  /// Unicode case folding, read one key-ordered page at a time.
  Future<List<ReferenceRow>> _scanRows(
    String datasetId, {
    required String needle,
    required int offset,
    required int limit,
  }) async {
    final int chunk = AppConstants.lists.pageSize;
    final List<ReferenceRow> matches = <ReferenceRow>[];
    int skipped = 0;
    ReferenceRow? after;
    while (matches.length < limit) {
      final List<ReferenceRow> rows = await _liveRows(
        datasetId,
        needle: '',
        offset: 0,
        limit: chunk,
        after: after,
      );
      for (final ReferenceRow row in rows) {
        if (matches.length == limit) {
          break;
        }
        if (!_rowMatches(row, needle)) {
          continue;
        }
        if (skipped < offset) {
          skipped++;
        } else {
          matches.add(row);
        }
      }
      if (rows.length < chunk) {
        break;
      }
      after = rows.last;
    }
    return matches;
  }

  ValidationFailure? _validateDataset(ReferenceDataset dataset) {
    if (dataset.name.trim().isEmpty || dataset.keyColumn.trim().isEmpty) {
      return const ValidationFailure(
        message: 'A dataset needs a name and a key column.',
        recoveryAction: 'Fill those fields and save again.',
      );
    }
    if (!dataset.columns.contains(dataset.keyColumn)) {
      return const ValidationFailure(
        message: 'The key column must be one of the dataset columns.',
        recoveryAction: 'Pick a key from the column list.',
      );
    }
    return null;
  }

  static bool _rowMatches(ReferenceRow row, String needle) {
    if (row.key.toLowerCase().contains(needle)) {
      return true;
    }
    for (final String value in row.values.values) {
      if (value.toLowerCase().contains(needle)) {
        return true;
      }
    }
    return false;
  }

  static bool _isAscii(String value) {
    return value.codeUnits.every((int unit) => unit < _asciiLimit);
  }

  static int _byName(ReferenceDataset a, ReferenceDataset b) {
    final int byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) {
      return byName;
    }
    return a.id.compareTo(b.id);
  }
}

/// Default stub — [main] overrides with [ReferenceRepositoryImpl].
final Provider<ReferenceRepository> referenceRepositoryProvider =
    Provider<ReferenceRepository>((Ref ref) {
      return _EmptyReferenceRepository();
    });

final class _EmptyReferenceRepository implements ReferenceRepository {
  @override
  Stream<List<ReferenceDataset>> watchAll() =>
      Stream<List<ReferenceDataset>>.value(const <ReferenceDataset>[]);

  @override
  Stream<List<ReferenceDataset>> watchByProject(String projectId) => watchAll();

  @override
  Future<Result<ReferenceDataset?>> byId(String id) async =>
      const Success<ReferenceDataset?>(null);

  @override
  Future<Result<ReferenceDataset>> save(ReferenceDataset dataset) async =>
      const FailureResult<ReferenceDataset>(_unavailable);

  @override
  Future<Result<ReferenceDataset>> importDataset({
    required ReferenceDataset dataset,
    required List<ReferenceRow> rows,
  }) async => const FailureResult<ReferenceDataset>(_unavailable);

  @override
  Future<Result<void>> delete(String id, {required String reason}) async =>
      const FailureResult<void>(_unavailable);

  @override
  Future<Result<List<ReferenceRow>>> pageRows({
    required String datasetId,
    required int offset,
    required int limit,
    String query = '',
  }) async => const Success<List<ReferenceRow>>(<ReferenceRow>[]);

  @override
  Future<Result<ReferenceRow?>> rowById(String id) async =>
      const Success<ReferenceRow?>(null);

  @override
  Future<Result<ReferenceRow>> saveRow(
    ReferenceRow row, {
    Map<String, String>? previousValues,
  }) async => const FailureResult<ReferenceRow>(_unavailable);

  @override
  Future<Result<ReferenceRow?>> lookupByKey({
    required String datasetId,
    required String keyValue,
  }) async => const Success<ReferenceRow?>(null);

  @override
  Future<Result<List<ReferenceRow>>> lookupByNormalised({
    required String datasetId,
    required String query,
  }) async => const Success<List<ReferenceRow>>(<ReferenceRow>[]);

  @override
  Future<Result<List<ReferenceRow>>> allRows(String datasetId) async =>
      const Success<List<ReferenceRow>>(<ReferenceRow>[]);
}

/// First code unit outside ASCII, the only range SQLite's lower() folds.
const int _asciiLimit = 0x80;

const StorageFailure _missing = StorageFailure(
  message: 'That row is no longer on this device.',
  recoveryAction: 'Refresh the list and try again.',
);

const StorageFailure _needsReason = StorageFailure(
  message: 'A delete needs a reason.',
  recoveryAction: 'Say why this row should be removed, then try again.',
);

const StorageFailure _unavailable = StorageFailure(
  message: 'Reference data is not available yet.',
  recoveryAction: 'Restart the app and try again.',
);
