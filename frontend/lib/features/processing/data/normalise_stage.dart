import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/processing_job.dart';
import '../domain/response_parser.dart';
import '../domain/row_matching.dart';
import 'on_device_stage.dart';
import 'record_bundle.dart';
import 'response_store.dart';
import 'stage_settings.dart';
import 'stage_support.dart';

/// The normalise stage: resolves the record to a predefined row from its
/// recognised text, and audits the match with its strategy and score.
///
/// Exact, alias, normalised and fuzzy matching run on the device against the
/// threshold in the settings store. Only when all four fall short is the
/// model's answer used: the row the extraction call already named, read from
/// its stored response, so no further request leaves the device.
final class NormaliseStage {
  /// Creates the stage over [db].
  const NormaliseStage({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._onDevice,
    required this._settings,
    required this._responses,
  });

  final AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final OnDeviceStage _onDevice;
  final StageSettings _settings;
  final ResponseStore _responses;

  /// Matches [bundle]'s record to a row unless it already has one.
  Future<void> run(
    ProcessingJob job,
    RecordBundle bundle,
    CancellationToken cancel,
  ) async {
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
      threshold: _settings.read(SettingKeys.aiRowMatchThreshold),
      classify: (String _, List<MatchableRow> rows) =>
          _modelRow(job, bundle, rows),
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

  /// The row the stored extraction response named, if it is one of [rows].
  Future<RowMatch?> _modelRow(
    ProcessingJob job,
    RecordBundle bundle,
    List<MatchableRow> rows,
  ) async {
    final List<ProcessingResult> stored = StageSupport.unwrap(
      await _responses.forJob(job.id),
    );
    for (final ProcessingResult response in stored.reversed) {
      if (!response.parsedOk ||
          StageSupport.summaryValue(response.requestSummary, 'kind') !=
              'online' ||
          StageSupport.summaryValue(response.requestSummary, 'operation') !=
              null) {
        continue;
      }
      final String? named = ResponseParser.parse(
        response.rawResponse,
        schema: StageSupport.schema(bundle.fields),
      ).matchedRow?.trim().toLowerCase();
      if (named == null || named.isEmpty) {
        continue;
      }
      for (final MatchableRow row in rows) {
        if (row.label.trim().toLowerCase() == named) {
          return (
            id: row.id,
            label: row.label,
            strategy: 'model',
            score: AppConstants.processing.rowMatchModelScore,
          );
        }
      }
    }
    return null;
  }
}
