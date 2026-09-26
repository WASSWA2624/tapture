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
import 'record_bundle.dart';
import 'response_store.dart';
import 'stage_support.dart';

/// Guarded proposals for a record, and why any candidate was dropped.
typedef ProposalSelection = ({
  List<ProposedValue> proposals,
  List<String> rejections,
});

/// Turns cached OCR candidates and stored provider responses into proposals
/// that have passed the no-invention guard.
final class ProposalCollector {
  /// Creates the collector over the OCR [cache] and stored [responses].
  const ProposalCollector({required this._cache, required this._responses});

  final OcrCache _cache;
  final ResponseStore _responses;

  /// Every guarded proposal for [job]'s record, local candidates first.
  ///
  /// The first proposal for a field wins; later ones for the same field are
  /// ignored.
  Future<ProposalSelection> collect(
    ProcessingJob job,
    RecordBundle bundle,
  ) async {
    final List<ProposedValue> proposals = <ProposedValue>[];
    final List<String> rejections = <String>[];
    final Set<String> proposedKeys = <String>{};
    final List<IdentityField> identity = StageSupport.identityFields(bundle);
    for (final Photo photo in bundle.photos) {
      final OcrResult? ocr = StageSupport.unwrap(
        await _cache.lookup(contentHash: photo.sha256, perceptualHash: ''),
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
        if (!proposedKeys.add(candidate.fieldKey)) {
          continue;
        }
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
        proposals.add((
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
    for (final ProcessingResult response in responses.reversed) {
      if (!response.parsedOk) {
        continue;
      }
      final ParseOutcome parsed = ResponseParser.parse(
        response.rawResponse,
        schema: StageSupport.schema(bundle.fields),
      );
      if (!parsed.ok) {
        continue;
      }
      for (final ParsedField parsedField in parsed.fields.values) {
        if (!proposedKeys.add(parsedField.key)) {
          continue;
        }
        final TemplateField field = bundle.fields.firstWhere(
          (TemplateField value) => value.fieldKey == parsedField.key,
        );
        final GuardOutcome guarded = NoInventionGuard.check(
          fieldKey: parsedField.key,
          value: parsedField.value,
          evidence: parsedField.evidence,
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
        final Photo? photo = bundle.photos.firstOrNull;
        proposals.add((
          fieldKey: parsedField.key,
          value: guarded.value,
          confidence: parsedField.confidence,
          evidence: EvidenceLinking.forValue(
            photoId: photo?.id,
            snippet: parsedField.evidence.join('\n'),
            confidence: parsedField.confidence,
          ),
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
