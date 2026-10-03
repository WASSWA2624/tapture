import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/variances.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/field_variance.dart';
import '../domain/variance_computation.dart';

/// Writes one record's variance rows (task 015).
///
/// A value filled from a register row carries `reference-row:<id>` as its
/// method, and its raw value is the register's value: capture writes it
/// there and an edit never overwrites it. Those raw values are the
/// as-recorded side; what each field displays now is the as-found side.
/// [VarianceComputation] classifies each mapped field over normalised
/// values, and each result is upserted on its (record, field) row, so a
/// rewrite touches that record's variance rows and nothing else.
abstract final class VarianceWriter {
  /// Method prefix of a value filled from a register row.
  static const String registerMethod = 'reference-row:';

  /// Recomputes and writes record [recordId]'s variances inside the open
  /// transaction on [db]. A record with no register values writes nothing.
  /// A failed write throws, so the caller's transaction rolls back.
  static Future<void> rewrite(
    AppDatabase db, {
    required String recordId,
    required Clock clock,
    required String deviceId,
    required IdService ids,
  }) async {
    final List<QueryRow> rows = await db
        .customSelect(
          'SELECT r.project_id AS project_id, f.field_key AS field_key, '
          'f.value_raw AS recorded, '
          'COALESCE(f.value_final, f.value_refined, f.value_raw) AS found '
          'FROM record_fields f JOIN records r ON r.id = f.record_id '
          "WHERE f.record_id = ? AND f.method LIKE '$registerMethod%' "
          'AND f.retired_at IS NULL AND NOT EXISTS (SELECT 1 FROM '
          "tombstones t WHERE t.entity_type = 'record_fields' "
          'AND t.entity_id = f.id) ORDER BY f.rowid',
          variables: <Variable<Object>>[Variable<String>(recordId)],
        )
        .get();
    if (rows.isEmpty) {
      return;
    }
    final String projectId = rows.first.read<String>('project_id');
    final List<FieldVariance> variances = VarianceComputation.compare(
      recorded: <String, Object?>{
        for (final QueryRow row in rows)
          row.read<String>('field_key'): row.read<String?>('recorded'),
      },
      found: <String, Object?>{
        for (final QueryRow row in rows)
          row.read<String>('field_key'): row.read<String?>('found'),
      },
      fieldKeys: <String>[
        for (final QueryRow row in rows) row.read<String>('field_key'),
      ],
    );
    for (final FieldVariance variance in variances) {
      final Result<Variance> written = await upsertVariance(
        db,
        row: VariancesCompanion.insert(
          projectId: projectId,
          recordId: recordId,
          fieldKey: variance.fieldKey,
          registerValue: Value<String?>(_text(variance.recorded)),
          foundValue: Value<String?>(_text(variance.found)),
          status: variance.status.name,
          createdAt: clock.nowUtc(),
          updatedAt: clock.nowUtc(),
          updatedByDevice: deviceId,
        ),
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      );
      if (written case FailureResult<Variance>(
        failure: final Failure varianceFailure,
      )) {
        throw varianceFailure;
      }
    }
  }

  /// Whether record [recordId] has variance rows, so an edit after approval
  /// knows to rewrite them.
  static Future<bool> exists(AppDatabase db, String recordId) async {
    final QueryRow? row = await db
        .customSelect(
          'SELECT 1 AS found FROM variances WHERE record_id = ? LIMIT 1',
          variables: <Variable<Object>>[Variable<String>(recordId)],
        )
        .getSingleOrNull();
    return row != null;
  }
}

String? _text(Object? value) => value?.toString();
