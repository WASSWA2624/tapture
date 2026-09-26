import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/field_evidence.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/normalise/choices.dart';
import 'package:tapture/core/normalise/dates.dart';
import 'package:tapture/core/normalise/units.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/projects.dart'
    show ProjectSettingsResolved;

import '../domain/evidence_linking.dart';
import '../domain/processing_job.dart';
import '../domain/proposal_application.dart';
import '../domain/provenance.dart';
import 'job_writes.dart';
import 'processing_repository_impl.dart';
import 'proposal_collector.dart';
import 'record_bundle.dart';
import 'stage_settings.dart';
import 'stage_support.dart';

/// The validate stage: applies guarded proposals as unapproved values with
/// evidence and an audited provenance stamp, then sets the record status.
///
/// Verified and hand-entered values are skipped, and the skip is recorded on
/// the job beside every rejection.
final class ValidateStage {
  /// Creates the stage over [db].
  const ValidateStage({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._ids,
    required this._settings,
    required this._collector,
    required this._writes,
  });

  final AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final StageSettings _settings;
  final ProposalCollector _collector;
  final JobWrites _writes;

  /// Applies [job]'s proposals to [bundle]'s record in one transaction.
  Future<void> run(
    ProcessingJob job,
    RecordBundle bundle,
    CancellationToken cancel,
  ) async {
    final List<ExistingValue> existing = <ExistingValue>[
      for (final RecordField field in bundle.existing)
        (
          fieldKey: field.fieldKey,
          capturedValue: field.valueRaw,
          verified: field.verified,
          source: field.source,
        ),
    ];
    final ProposalSelection selection = await _collector.collect(job, bundle);
    final ProjectSettingsResolved settings = _settings.project(bundle);
    final ApplicationPlan plan = ProposalApplication.apply(
      proposals: selection.proposals,
      existing: existing,
      high: settings.confidenceHigh,
      medium: settings.confidenceMedium,
      requiredKeys: <String>[
        for (final TemplateField field in bundle.fields)
          if (field.isRequired) field.fieldKey,
      ],
    );
    final List<String> priorRejections = await _writes.rejections(job.id);
    await _db.transaction(() async {
      for (final ProposalWrite write in plan.writes) {
        final TemplateField field = bundle.fields.firstWhere(
          (TemplateField value) => value.fieldKey == write.fieldKey,
        );
        final ({String raw, String? normalised}) value = _normalise(
          write.proposed ?? '',
          field,
        );
        final RecordField stored = StageSupport.unwrap(
          await insertProcessingProposal(
            _db,
            recordId: bundle.record.id,
            fieldKey: write.fieldKey,
            rawValue: value.raw,
            normalisedValue: value.normalised,
            confidence: write.confidence,
            confidenceBand: write.band.name,
            source: write.provenance.source,
            method: write.provenance.method,
            provider: write.provenance.provider,
            model: write.provenance.model,
            promptVersion: write.provenance.promptVersion,
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
            auditReason: jsonEncode(Provenance.asAudit(write.provenance)),
          ),
        );
        for (final EvidenceDraft evidence in write.evidence) {
          StageSupport.unwrap(
            await insertFieldEvidence(
              _db,
              row: FieldEvidenceCompanion(
                recordFieldId: Value<String>(stored.id),
                sourceType: Value<FieldEvidenceSource>(
                  _evidenceSource(evidence.sourceType),
                ),
                photoId: Value<String?>(evidence.photoId),
                region: Value<String?>(evidence.regionJson),
                snippet: Value<String?>(evidence.snippet),
                confidence: Value<double?>(evidence.confidence),
              ),
              clock: _clock,
              deviceId: _deviceId,
              ids: _ids,
            ),
          );
        }
      }
      await (_db.update(_db.records)
            ..where(($RecordsTable table) => table.id.equals(bundle.record.id)))
          .write(RecordsCompanion(status: Value<String>(plan.status)));
      await (_db.update(
        _db.processing,
      )..where(($ProcessingTable table) => table.id.equals(job.id))).write(
        ProcessingCompanion(
          rejections: Value<String?>(
            priorRejections.isEmpty &&
                    selection.rejections.isEmpty &&
                    plan.skips.isEmpty
                ? null
                : jsonEncode(
                    <String>{
                      ...priorRejections,
                      ...selection.rejections,
                      ...plan.skips,
                    }.toList(),
                  ),
          ),
        ),
      );
    });
  }
}

({String raw, String? normalised}) _normalise(String raw, TemplateField field) {
  if (field.unit != null && field.unit!.isNotEmpty) {
    final UnitValue? converted = Units.convert(raw, targetUnit: field.unit!);
    if (converted != null) {
      return (raw: converted.original, normalised: converted.stored);
    }
  }
  final List<ChoiceOption> options = StageSupport.choiceOptions(field.options);
  if (options.isNotEmpty) {
    final ChoiceMatch? choice = Choices.match(raw, options: options);
    if (choice != null) {
      return (raw: choice.original, normalised: choice.label);
    }
  }
  if (field.type.toLowerCase() == 'date') {
    final DateValue? date = Dates.parse(raw, locale: 'en-UG');
    if (date != null) {
      return (raw: date.original, normalised: date.stored);
    }
  }
  return (raw: raw, normalised: null);
}

FieldEvidenceSource _evidenceSource(String source) {
  return switch (source) {
    'document' => FieldEvidenceSource.document,
    'transcript' => FieldEvidenceSource.transcript,
    _ => FieldEvidenceSource.photo,
  };
}
