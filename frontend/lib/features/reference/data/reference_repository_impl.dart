import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
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
          return FailureResult<ReferenceDataset>(
            ValidationFailure(
              localizedMessage:
                  Copy.messages.failureThatKeyColumnHasDuplicateValues,
              localizedRecovery:
                  Copy.messages.failurePickAnotherKeyColumnOrConfirmDuplicates,
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
      return FailureResult<void>(_missing);
    }
    if (reason.trim().isEmpty) {
      return FailureResult<void>(_needsReason);
    }
    return runInTransaction(_db, () async {
      final sqlite.ReferenceDatasetRow? header = await _header(id);
      if (header == null || await _isTombstoned(_db.reference, id)) {
        throw StorageFailure(
          localizedMessage: Copy.messages.failureThatRowIsNoLongerOnThis,
          localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
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
      return Success<List<ReferenceRow>>(
        await _page(datasetId, query: query, offset: offset, limit: limit),
      );
    } on Failure catch (failure) {
      return FailureResult<List<ReferenceRow>>(failure);
    } on Object catch (error) {
      return FailureResult<List<ReferenceRow>>(storageFailureFrom(error));
    }
  }

  @override
  Stream<int> watchRowCount({required String datasetId, String query = ''}) {
    final String needle = query.trim().toLowerCase();
    return _changes().asyncMap(
      (_) => _guarded(
        () => _isAscii(needle)
            ? _countLive(datasetId, needles: _needles(needle))
            : _scanCount(datasetId, needle: needle),
      ),
    );
  }

  @override
  Stream<List<ReferenceRow>> watchRows({
    required String datasetId,
    required int offset,
    required int limit,
    String query = '',
  }) {
    return _changes().asyncMap(
      (_) => _guarded(
        () => _page(datasetId, query: query, offset: offset, limit: limit),
      ),
    );
  }

  /// [read], with any error a stream reader sees as a typed [Failure].
  Future<T> _guarded<T>(Future<T> Function() read) async {
    try {
      return await read();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      final StorageFailure readFailure = storageFailureFrom(error);
      throw readFailure;
    }
  }

  /// One page of [datasetId]'s rows [query] keeps, in key order.
  ///
  /// SQLite's lower() folds ASCII letters only, so only an ASCII needle is
  /// filtered and paged in SQLite. Any other needle is narrowed in SQLite to
  /// rows holding one of its case forms, then kept by Dart's Unicode case
  /// folding over bounded key-ordered chunks. Either way only the requested
  /// page crosses the repository boundary.
  Future<List<ReferenceRow>> _page(
    String datasetId, {
    required String query,
    required int offset,
    required int limit,
  }) {
    if (limit <= 0) {
      return Future<List<ReferenceRow>>.value(const <ReferenceRow>[]);
    }
    final String needle = query.trim().toLowerCase();
    final int start = offset < 0 ? 0 : offset;
    return _isAscii(needle)
        ? _liveRows(
            datasetId,
            needles: _needles(needle),
            offset: start,
            limit: limit,
          )
        : _scanRows(datasetId, needle: needle, offset: start, limit: limit);
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
      return FailureResult<ReferenceRow>(
        ValidationFailure(
          localizedMessage: Copy.messages.failureARowNeedsADatasetAndA,
          localizedRecovery: Copy.messages.failureFillThoseFieldsAndSaveAgain,
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
            localizedMessage: failure.localizedMessage,
            recoveryAction: failure.recoveryAction ?? 'Try again.',
            localizedRecovery: failure.localizedRecovery,
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
      final int count = await _countLive(
        row.datasetId,
        needles: const <String>[],
      );
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

  /// Live rows of [datasetId] holding one of [needles] under SQLite's ASCII
  /// folding, counted in SQLite rather than loaded (FE-PERF-06).
  Future<int> _countLive(
    String datasetId, {
    required List<String> needles,
  }) async {
    final QueryRow row = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM reference_rows r '
          'WHERE ${_liveWhere(needles.length)}',
          variables: _liveVariables(datasetId, needles),
          readsFrom: <TableInfo<Table, Object?>>{
            _db.referenceRows,
            _db.tombstones,
          },
        )
        .getSingle();
    return row.read<int>('n');
  }

  /// Rows of [datasetId] that [needle] keeps under Dart's Unicode folding,
  /// counted a bounded chunk at a time.
  Future<int> _scanCount(String datasetId, {required String needle}) async {
    int count = 0;
    await _scan(datasetId, needle, (ReferenceRow _) {
      count++;
      return true;
    });
    return count;
  }

  /// Walks [datasetId]'s live rows in key order, a bounded chunk at a time,
  /// handing [found] each row [needle] keeps under Dart's Unicode folding
  /// until it answers false.
  ///
  /// SQLite first narrows the walk to rows holding one of the needle's case
  /// forms, so a search reads its likely rows rather than the dataset.
  Future<void> _scan(
    String datasetId,
    String needle,
    bool Function(ReferenceRow row) found,
  ) async {
    final int chunk = AppConstants.datasets.scanChunk;
    final List<String> forms = _caseForms(needle);
    ({String key, String id})? after;
    while (true) {
      final List<sqlite.ReferenceLookupRow> rows = await _livePage(
        datasetId,
        needles: forms,
        offset: 0,
        limit: chunk,
        after: after,
      );
      for (final sqlite.ReferenceLookupRow raw in rows) {
        final ReferenceRow row = ReferenceMapper.rowFromRow(raw);
        if (_rowMatches(row, needle) && !found(row)) {
          return;
        }
      }
      if (rows.length < chunk) {
        return;
      }
      after = (key: rows.last.keyValue, id: rows.last.id);
    }
  }

  /// One event now, and one whenever a dataset, a row or a tombstone is
  /// written, so every watch re-reads what it shows. Only the notice is
  /// watched; no table is read to produce it.
  Stream<void> _changes() {
    return Stream<void>.multi((MultiStreamController<void> listener) {
      listener.add(null);
      final StreamSubscription<Set<TableUpdate>> updates = _db
          .tableUpdates(
            TableUpdateQuery.onAllTables(<TableInfo<Table, Object?>>[
              _db.reference,
              _db.referenceRows,
              _db.tombstones,
            ]),
          )
          .listen((_) => listener.add(null));
      listener.onCancel = updates.cancel;
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

  /// Live rows of [datasetId] in key order.
  ///
  /// Non-empty [needles] keep rows whose key or a visible value contains one
  /// of them after SQLite's ASCII case folding; the device marker is never
  /// searched.
  Future<List<ReferenceRow>> _liveRows(
    String datasetId, {
    required List<String> needles,
    required int offset,
    required int limit,
  }) async {
    return <ReferenceRow>[
      for (final sqlite.ReferenceLookupRow row in await _livePage(
        datasetId,
        needles: needles,
        offset: offset,
        limit: limit,
      ))
        ReferenceMapper.rowFromRow(row),
    ];
  }

  /// The stored rows [_liveRows] maps, not yet decoded, resuming just past
  /// [after].
  Future<List<sqlite.ReferenceLookupRow>> _livePage(
    String datasetId, {
    required List<String> needles,
    required int offset,
    required int limit,
    ({String key, String id})? after,
  }) async {
    // A row-value bound lets SQLite seek the key index straight to the
    // next chunk instead of re-reading every earlier row.
    final List<QueryRow> page = await _db
        .customSelect(
          '''SELECT r.* FROM reference_rows r
WHERE ${_liveWhere(needles.length)}
${after == null ? '' : 'AND (r.key_value, r.id) > (?, ?)'}
ORDER BY r.key_value, r.id LIMIT ? OFFSET ?''',
          variables: <Variable<Object>>[
            ..._liveVariables(datasetId, needles),
            if (after != null) ...<Variable<Object>>[
              Variable<String>(after.key),
              Variable<String>(after.id),
            ],
            Variable<int>(limit),
            Variable<int>(offset),
          ],
          readsFrom: <TableInfo<Table, Object?>>{
            _db.referenceRows,
            _db.tombstones,
          },
        )
        .get();
    return <sqlite.ReferenceLookupRow>[
      for (final QueryRow row in page) _db.referenceRows.map(row.data),
    ];
  }

  /// Rows of [datasetId] whose key or a value contains [needle] under Dart's
  /// Unicode case folding: the page from [offset], at most [limit] rows.
  Future<List<ReferenceRow>> _scanRows(
    String datasetId, {
    required String needle,
    required int offset,
    required int limit,
  }) async {
    final List<ReferenceRow> matches = <ReferenceRow>[];
    int skipped = 0;
    await _scan(datasetId, needle, (ReferenceRow row) {
      if (skipped < offset) {
        skipped++;
      } else {
        matches.add(row);
      }
      return matches.length < limit;
    });
    return matches;
  }

  ValidationFailure? _validateDataset(ReferenceDataset dataset) {
    if (dataset.name.trim().isEmpty || dataset.keyColumn.trim().isEmpty) {
      return ValidationFailure(
        localizedMessage: Copy.messages.failureADatasetNeedsANameAndA,
        localizedRecovery: Copy.messages.failureFillThoseFieldsAndSaveAgain,
      );
    }
    if (!dataset.columns.contains(dataset.keyColumn)) {
      return ValidationFailure(
        localizedMessage: Copy.messages.failureTheKeyColumnMustBeOneOf,
        localizedRecovery: Copy.messages.failurePickAKeyFromTheColumnList,
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

  /// [needle] as the one string SQLite looks for, or none when empty.
  static List<String> _needles(String needle) {
    return needle.isEmpty ? const <String>[] : <String>[needle];
  }

  /// The case forms of [needle] SQLite can find after folding only ASCII:
  /// each letter outside ASCII both as typed and upper-cased. Past
  /// [_maxCaseForms] forms only the needle's start is looked for, which a
  /// row holding the needle still holds. Dart's folding then decides.
  static List<String> _caseForms(String needle) {
    List<String> forms = <String>[''];
    for (final int rune in needle.runes) {
      final String letter = String.fromCharCode(rune);
      final String upper = letter.toUpperCase();
      final List<String> cases =
          rune < _asciiLimit || upper == letter || upper.runes.length != 1
          ? <String>[letter]
          : <String>[letter, upper];
      if (forms.length * cases.length > _maxCaseForms) {
        break;
      }
      forms = <String>[
        for (final String form in forms)
          for (final String variant in cases) '$form$variant',
      ];
    }
    return forms;
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
      FailureResult<ReferenceDataset>(_unavailable);

  @override
  Future<Result<ReferenceDataset>> importDataset({
    required ReferenceDataset dataset,
    required List<ReferenceRow> rows,
  }) async => FailureResult<ReferenceDataset>(_unavailable);

  @override
  Future<Result<void>> delete(String id, {required String reason}) async =>
      FailureResult<void>(_unavailable);

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
  }) async => FailureResult<ReferenceRow>(_unavailable);

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
  Stream<int> watchRowCount({required String datasetId, String query = ''}) =>
      Stream<int>.value(0);

  @override
  Stream<List<ReferenceRow>> watchRows({
    required String datasetId,
    required int offset,
    required int limit,
    String query = '',
  }) => Stream<List<ReferenceRow>>.value(const <ReferenceRow>[]);
}

/// First code unit outside ASCII, the only range SQLite's lower() folds.
const int _asciiLimit = 0x80;

/// The most case forms a search outside ASCII hands SQLite.
const int _maxCaseForms = 16;

/// The live rows of one dataset that hold one of [needles] needles: not
/// tombstoned, and, when there are needles, one found in the key or a
/// visible value after SQLite's ASCII folding. The device marker is never
/// searched. Its variables come from [_liveVariables].
String _liveWhere(int needles) {
  const String live = '''r.dataset_id = ?
AND NOT EXISTS (SELECT 1 FROM tombstones t
  WHERE t.entity_type = 'reference_rows' AND t.entity_id = r.id)''';
  if (needles == 0) {
    return live;
  }
  final String inKey = List<String>.filled(
    needles,
    'instr(lower(r.key_value), ?) > 0',
  ).join(' OR ');
  final String inCell = List<String>.filled(
    needles,
    'instr(lower(CAST(cell.value AS TEXT)), ?) > 0',
  ).join(' OR ');
  return '''$live
AND ($inKey OR EXISTS (
  SELECT 1 FROM json_each(r."values") cell
  WHERE cell.key <> ? AND ($inCell)))''';
}

/// The variables [_liveWhere] binds for [needles], in order.
List<Variable<Object>> _liveVariables(String datasetId, List<String> needles) {
  return <Variable<Object>>[
    Variable<String>(datasetId),
    for (final String needle in needles) Variable<String>(needle),
    if (needles.isNotEmpty)
      const Variable<String>(ReferenceMapper.addedOnDeviceKey),
    for (final String needle in needles) Variable<String>(needle),
  ];
}

final StorageFailure _missing = StorageFailure(
  localizedMessage: Copy.messages.failureThatRowIsNoLongerOnThis,
  localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
);

final StorageFailure _needsReason = StorageFailure(
  localizedMessage: Copy.messages.failureADeleteNeedsAReason,
  localizedRecovery: Copy.messages.failureSayWhyThisRowShouldBeRemoved,
);

final StorageFailure _unavailable = StorageFailure(
  localizedMessage: Copy.messages.failureReferenceDataIsNotAvailableYet,
  localizedRecovery: Copy.messages.failureRestartTheAppAndTryAgain,
);
