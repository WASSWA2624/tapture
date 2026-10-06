import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/db/app_database.dart';

import '../domain/evidence_linking.dart';
import '../domain/identifier_extraction.dart';
import '../domain/no_invention_guard.dart';
import '../domain/processing_job.dart';
import '../domain/proposal_application.dart';
import '../domain/provenance.dart';
import '../domain/response_parser.dart';
import 'ocr_cache.dart';
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
    final List<IdentityField> identity = StageSupport.identityFields(bundle);
    for (final Photo photo in bundle.photos) {
      final OcrResult? ocr = StageSupport.unwrap(
        await _cache.lookup(
          contentHash:
              await _paths?.ocrContentHash(bundle, photo) ?? photo.sha256,
          perceptualHash: '',
        ),
      );
      if (ocr == null) {
        continue;
      }
      final List<PlateBlock> blocks = <PlateBlock>[
        for (final block in ocr.blocks)
          (
            text: block.text,
            top: block.bounds.top,
            confidence: block.confidence,
          ),
      ];
      for (final IdentifierCandidate candidate in IdentifierExtraction.extract(
        text: ocr.text,
        blocks: blocks,
        fields: identity,
      )) {
        final field = bundle.fields.firstWhere(
          (TemplateField value) => value.fieldKey == candidate.fieldKey,
        );
        final GuardOutcome guarded = NoInventionGuard.check(
          fieldKey: candidate.fieldKey,
          value: candidate.value,
          evidence: <String>[candidate.blockText],
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
        final OcrBlock? origin = ocr.blocks
            .where((OcrBlock block) => block.text == candidate.blockText)
            .firstOrNull;
        _add(proposals, conflicts, rejections, (
          fieldKey: candidate.fieldKey,
          value: guarded.value,
          confidence: candidate.confidence,
          evidence: EvidenceLinking.forValue(
            photoId: photo.id,
            regionJson: origin == null ? null : StageSupport.region(origin),
            snippet: candidate.blockText,
            confidence: candidate.confidence,
          ),
          provenance: Provenance.stamp(
            source: 'ocr',
            method: 'identifier-pattern',
            provider: 'on-device',
            model: 'ml-kit-text-recognition',
            promptVersion: 'local-1',
          ),
        ));
      }
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
      final Object? summary = StageSupport.json(response.requestSummary);
      if (!response.parsedOk ||
          (summary is Map &&
              currentRequest != null &&
              summary['projectRevision'] != null &&
              summary['projectRevision'] != currentRequest) ||
          (summary is Map &&
              summary['sourceRevision'] != null &&
              summary['sourceRevision'] != currentRevision) ||
          (summary is Map &&
              (summary['requestGeneration'] ?? 0) != job.requestGeneration)) {
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
        schema: StageSupport.schema(bundle.fields),
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
        ));
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
) {
  if (conflicts.contains(candidate.fieldKey)) return;
  final ProposedValue? prior = proposals
      .where((ProposedValue value) => value.fieldKey == candidate.fieldKey)
      .firstOrNull;
  if (prior == null) {
    proposals.add(candidate);
    return;
  }
  if (prior.value?.trim().toLowerCase() ==
      candidate.value?.trim().toLowerCase()) {
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
