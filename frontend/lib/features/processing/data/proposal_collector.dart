import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, TemplateMapper;

import '../domain/evidence_linking.dart';
import '../domain/no_invention_guard.dart';
import '../domain/ocr_field_value.dart';
import '../domain/processing_job.dart';
import '../domain/proposal_application.dart';
import '../domain/provenance.dart';
import '../domain/response_parser.dart';
import 'ocr_cache.dart';
import 'ocr_proposals.dart';
import 'photo_paths.dart';
import 'processing_evidence.dart';
import 'processing_snapshot.dart';
import 'record_bundle.dart';
import 'response_store.dart';
import 'stage_support.dart';

/// Turns cached OCR candidates and stored provider responses into proposals
/// that have passed the no-invention guard.
final class ProposalCollector {
  /// Creates the collector over the OCR [cache] and stored [responses].
  const ProposalCollector({
    required this._cache,
    required this._responses,
    this._paths,
    this._currentRevision,
  });

  final OcrCache _cache;
  final ResponseStore _responses;
  final PhotoPaths? _paths;
  final Future<String> Function(ProcessingJob, RecordBundle)? _currentRevision;

  /// Every guarded proposal for [job]'s record, local candidates first.
  ///
  /// Conflicting supported values remain unresolved for a person to review.
  Future<ProposalSelection> collect(
    ProcessingJob job,
    RecordBundle bundle,
  ) async {
    final List<ProposedValue> proposals = <ProposedValue>[];
    final List<String> rejections = <String>[];
    final Set<String> conflicts = <String>{};
    final Map<String, FieldDef> fields = <String, FieldDef>{
      for (final TemplateField field in StageSupport.extractionFields(bundle))
        field.fieldKey: TemplateMapper.fieldFromRow(field),
    };
    final local = await OcrProposals(
      cache: _cache,
      paths: _paths,
    ).collect(bundle);
    rejections.addAll(local.findings);
    for (final ProposedValue candidate in local.proposals) {
      _add(
        proposals,
        conflicts,
        rejections,
        candidate,
        fields[candidate.fieldKey],
      );
    }
    final List<ProcessingResult> responses = StageSupport.unwrap(
      await _responses.forJob(job.id),
    );
    final Map<String, Map<String, Object?>> sources = await ProcessingEvidence(
      cache: _cache,
      paths: _paths,
    ).catalogue(bundle, responses);
    final String currentRevision = await ProcessingSnapshot.sourceRevision(
      bundle,
      privacyRevision: '',
    );
    final String? currentRequest = await _currentRevision?.call(job, bundle);
    for (final ProcessingResult response in responses.reversed) {
      rejections.addAll(
        StageSupport.rejectedFields(response.rawResponse, bundle),
      );
      final Object? summary = StageSupport.json(response.requestSummary);
      if (!response.parsedOk ||
          summary is! Map ||
          currentRequest == null ||
          !const <String>{'online', 'cache'}.contains(summary['kind']) ||
          summary['projectRevision'] != currentRequest ||
          summary['sourceRevision'] != currentRevision ||
          summary['privacyRevision'] is! String ||
          summary['sources'] is! List ||
          summary['requestGeneration'] != job.requestGeneration) {
        continue;
      }
      final String? privacy = StageSupport.summaryValue(
        response.requestSummary,
        'privacyRevision',
      );
      if (privacy != null &&
          _paths != null &&
          await _paths.privacyRevision(bundle) != privacy) {
        continue;
      }
      final ParseOutcome parsed = ResponseParser.parse(
        response.rawResponse,
        schema: StageSupport.schema(StageSupport.extractionFields(bundle)),
      );
      if (!parsed.ok) {
        continue;
      }
      final Object? findings = StageSupport.json(response.rawResponse);
      if (findings is Map && findings['groupingUncertain'] == true) {
        rejections.add(
          'Item grouping is uncertain. Review the linked evidence.',
        );
      }
      if (findings is Map &&
          findings['conflicts'] is List &&
          (findings['conflicts'] as List).isNotEmpty) {
        rejections.add(
          'The sources contain conflicting values. Review the linked evidence.',
        );
      }
      for (final ParsedField parsedField in parsed.fields.values) {
        final TemplateField field = bundle.fields.firstWhere(
          (TemplateField value) => value.fieldKey == parsedField.key,
        );
        if (field.type == 'consent') continue;
        final List<EvidenceDraft> evidence = ProcessingEvidence.resolve(
          value: parsedField.value ?? '',
          references: parsedField.evidence,
          catalogue: sources,
          requestSummary: response.requestSummary,
          confidence: parsedField.confidence,
        );
        final GuardOutcome guarded = NoInventionGuard.check(
          fieldKey: parsedField.key,
          value: parsedField.value,
          evidence: evidence.isEmpty ? const <String>[] : parsedField.evidence,
          evidenceRequired: true,
          pattern: StageSupport.pattern(field),
          options: StageSupport.optionValues(field.options),
        );
        if (guarded.value == null) {
          if (guarded.rejection case final GuardRejection rejection) {
            rejections.add(rejection.reason);
          }
          continue;
        }
        final FieldDef definition = fields[parsedField.key]!;
        if (OcrFieldValue.read(guarded.value!, definition) == null) {
          rejections.add(
            'The proposed value for ${parsedField.key} needs manual review.',
          );
          continue;
        }
        _add(proposals, conflicts, rejections, (
          fieldKey: parsedField.key,
          value: guarded.value,
          confidence: parsedField.confidence,
          evidence: evidence,
          provenance: Provenance.stamp(
            source: 'extraction',
            method: 'provider',
            provider:
                StageSupport.summaryValue(
                  response.requestSummary,
                  'provider',
                ) ??
                job.provider ??
                'backend',
            model:
                StageSupport.summaryValue(response.requestSummary, 'model') ??
                job.model ??
                '',
            promptVersion:
                StageSupport.summaryValue(
                  response.requestSummary,
                  'promptVersion',
                ) ??
                'extraction-1',
          ),
        ), fields[parsedField.key]);
      }
    }
    return (proposals: proposals, rejections: rejections);
  }
}

void _add(
  List<ProposedValue> proposals,
  Set<String> conflicts,
  List<String> findings,
  ProposedValue candidate,
  FieldDef? field,
) {
  if (conflicts.contains(candidate.fieldKey)) return;
  final ProposedValue? prior = proposals
      .where((ProposedValue value) => value.fieldKey == candidate.fieldKey)
      .firstOrNull;
  if (prior == null) {
    proposals.add(candidate);
    return;
  }
  final String? previous = field == null
      ? prior.value
      : OcrFieldValue.read(prior.value ?? '', field) ?? prior.value;
  final String? next = field == null
      ? candidate.value
      : OcrFieldValue.read(candidate.value ?? '', field) ?? candidate.value;
  if (previous?.trim().toLowerCase() == next?.trim().toLowerCase()) {
    final ProposedValue selected = candidate.confidence > prior.confidence
        ? candidate
        : prior;
    proposals[proposals.indexOf(prior)] = (
      fieldKey: selected.fieldKey,
      value: selected.value,
      confidence: selected.confidence,
      evidence: <EvidenceDraft>{
        ...prior.evidence,
        ...candidate.evidence,
      }.toList(),
      provenance: selected.provenance,
    );
    return;
  }
  proposals.removeWhere(
    (ProposedValue value) => value.fieldKey == candidate.fieldKey,
  );
  conflicts.add(candidate.fieldKey);
  findings.add(
    'Conflicting values for ${candidate.fieldKey}. Review the linked evidence.',
  );
}

/// Guarded proposals for a record, and why any candidate was dropped.
typedef ProposalSelection = ({
  List<ProposedValue> proposals,
  List<String> rejections,
});
