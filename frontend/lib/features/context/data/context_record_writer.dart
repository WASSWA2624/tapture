import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/context_application.dart';
import '../domain/context_override.dart';
import '../domain/context_state.dart';

/// Writes context onto one record and keeps the raw value when it is edited.
///
/// Project context and every other record are left untouched.
final class ContextRecordWriter {
  /// Opens against [_db].
  ContextRecordWriter({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._ids,
    this.operator = '',
  });

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final String operator;

  /// Writes every level and pin with source [ContextApplication.source],
  /// then stores the whole context as this record's snapshot.
  Future<Result<void>> applyToRecord({
    required String recordId,
    required ContextState state,
  }) {
    final ({
      List<({String fieldKey, String value, String source})> fields,
      Map<String, Object?> snapshot,
    })
    applied = ContextApplication.apply(state);
    return runInTransaction(_db, () async {
      final DateTime now = _clock.nowUtc();
      await (_db.update(
        _db.records,
      )..where((sqlite.$RecordsTable tbl) => tbl.id.equals(recordId))).write(
        sqlite.RecordsCompanion(
          contextJson: Value<String>(jsonEncode(applied.snapshot)),
          updatedAt: Value<DateTime>(now),
          updatedByDevice: Value<String>(_deviceId),
        ),
      );
      for (final ({String fieldKey, String value, String source}) field
          in applied.fields) {
        final Result<sqlite.RecordField> written = await insertRecordField(
          _db,
          row: sqlite.RecordFieldsCompanion.insert(
            recordId: recordId,
            fieldKey: field.fieldKey,
            valueRaw: Value<String>(field.value),
            source: field.source,
            createdAt: now,
            updatedAt: now,
            updatedByDevice: _deviceId,
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
          operator: operator,
        );
        if (written case FailureResult<sqlite.RecordField>(
          :final Failure failure,
        )) {
          throw StorageFailure(
            message: failure.message,
            recoveryAction: failure.recoveryAction ?? 'Try again.',
          );
        }
      }
    });
  }

  /// Writes [newValue] beside the raw CONTEXT value and an audit row.
  ///
  /// Does not update project context or any other record.
  Future<Result<void>> overrideField({
    required String recordId,
    required String fieldKey,
    required String newValue,
  }) async {
    final sqlite.RecordField? existing =
        await (_db.select(_db.recordFields)..where(
              (sqlite.$RecordFieldsTable tbl) =>
                  tbl.recordId.equals(recordId) & tbl.fieldKey.equals(fieldKey),
            ))
            .getSingleOrNull();
    if (existing == null) {
      return const FailureResult<void>(
        ValidationFailure(
          message: 'That field is not on this record.',
          recoveryAction: 'Open the record and try again.',
        ),
      );
    }
    final ({
      String fieldKey,
      String rawValue,
      String refinedValue,
      bool overridden,
    })
    planned = ContextOverride.plan(
      fieldKey: fieldKey,
      rawValue: existing.valueRaw ?? '',
      newValue: newValue,
    );
    if (!planned.overridden) {
      return const Success<void>(null);
    }
    final Result<sqlite.RecordField> written = await writeRecordFieldRefined(
      _db,
      id: existing.id,
      valueRefined: planned.refinedValue,
      clock: _clock,
      deviceId: _deviceId,
      ids: _ids,
      operator: operator,
    );
    return switch (written) {
      Success<sqlite.RecordField>() => const Success<void>(null),
      FailureResult<sqlite.RecordField>(:final Failure failure) =>
        FailureResult<void>(failure),
    };
  }
}
