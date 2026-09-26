import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/row_matching.dart';
import 'on_device_stage.dart';
import 'record_bundle.dart';
import 'stage_support.dart';

/// The normalise stage: resolves the record to a predefined row from its
/// recognised text, and audits the match with its strategy and score.
final class NormaliseStage {
  /// Creates the stage over [db].
  const NormaliseStage({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._onDevice,
  });

  final AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final OnDeviceStage _onDevice;

  /// Matches [bundle]'s record to a row unless it already has one.
  Future<void> run(RecordBundle bundle, CancellationToken cancel) async {
    if (bundle.record.templateRowId != null || bundle.rows.isEmpty) {
      return;
    }
    final RowMatch? match = await RowMatching.match(
      query: await _onDevice.text(bundle),
      rows: <MatchableRow>[
        for (final TemplateRow row in bundle.rows)
          (
            id: row.id,
            label: row.label,
            aliases: StageSupport.strings(row.aliases),
          ),
      ],
    );
    if (match == null) {
      return;
    }
    await _db.transaction(() async {
      await (_db.update(_db.records)
            ..where(($RecordsTable table) => table.id.equals(bundle.record.id)))
          .write(
            RecordsCompanion(
              templateRowId: Value<String>(match.id),
              rowMatchStrategy: Value<String>(match.strategy),
              rowMatchScore: Value<double>(match.score),
              updatedAt: Value<DateTime>(_clock.nowUtc()),
              updatedByDevice: Value<String>(_deviceId),
              rev: Value<int>(bundle.record.rev + 1),
            ),
          );
      await appendAudit(
        _db,
        entityType: 'records',
        entityId: bundle.record.id,
        action: AuditAction.updated,
        fieldKey: 'templateRowId',
        previousValue: bundle.record.templateRowId,
        newValue: match.id,
        reason: jsonEncode(<String, Object>{
          'method': match.strategy,
          'score': match.score,
        }),
        clock: _clock,
        device: _deviceId,
      );
    });
  }
}
