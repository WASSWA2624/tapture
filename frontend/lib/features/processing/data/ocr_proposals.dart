import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/templates/templates.dart' show TemplateMapper;

import '../domain/evidence_linking.dart';
import '../domain/identifier_extraction.dart';
import '../domain/identifier_ownership.dart';
import '../domain/no_invention_guard.dart';
import '../domain/ocr_field_mapping.dart';
import '../domain/ocr_field_value.dart';
import '../domain/ocr_mapped_field.dart';
import '../domain/ocr_mapping_outcome.dart';
import '../domain/ocr_mapping_profile.dart';
import '../domain/ocr_parameter_block.dart';
import '../domain/proposal_application.dart';
import '../domain/provenance.dart';
import 'ocr_cache.dart';
import 'photo_paths.dart';
import 'record_bundle.dart';
import 'stage_support.dart';

/// Reads supported local parameters beside their immutable photo evidence.
final class OcrProposals {
  /// Uses the shared OCR cache and privacy-aware prepared content hashes.
  const OcrProposals({required this._cache, this._paths});

  final OcrCache _cache;
  final PhotoPaths? _paths;

  /// Candidates remain unapproved; conflicting values are resolved by review.
  Future<({List<ProposedValue> proposals, List<String> findings})> collect(
    RecordBundle bundle,
  ) async {
    final List<ProposedValue> proposals = <ProposedValue>[];
    final List<String> findings = <String>[];
    final OcrMappingProfile profile = OcrMappingProfile.fromTemplate(
      TemplateMapper.fromRows(
        header: bundle.template,
        fields: bundle.fields,
        rows: bundle.rows,
      ),
    );
    final List<IdentityField> identity = StageSupport.identityFields(bundle);
    for (final Photo photo in bundle.photos) {
      final OcrResult? ocr = StageSupport.unwrap(
        await _cache.lookup(
          contentHash:
              await _paths?.ocrContentHash(bundle, photo) ?? photo.sha256,
          perceptualHash: '',
        ),
      );
      if (ocr == null) continue;
      final OcrMappingOutcome mapped = OcrFieldMapping.extract(
        text: ocr.text,
        profile: profile,
        targetKeys: <String>{
          for (final TemplateField field in StageSupport.extractionFields(
            bundle,
          ))
            field.fieldKey,
        },
        blocks: <OcrParameterBlock>[
          for (final OcrBlock block in ocr.blocks)
            (
              text: block.text,
              left: block.bounds.left,
              top: block.bounds.top,
              right: block.bounds.right,
              bottom: block.bounds.bottom,
              confidence: block.confidence,
            ),
        ],
      );
      findings.addAll(mapped.findings);
      for (final OcrMappedField candidate in mapped.candidates) {
        proposals.add(
          _proposal(
            photo: photo,
            ocr: ocr,
            fieldKey: candidate.fieldKey,
            value: candidate.value,
            snippet: candidate.snippet,
            confidence: candidate.confidence,
            index: candidate.blockIndex,
            method: 'template-parameter',
          ),
        );
      }
      String unlabelled(String text) => text
          .split(RegExp(r'[\r\n]+'))
          .where((String line) => profile.matches(line).isEmpty)
          .join('\n');
      final identified = IdentifierOwnership.resolve(
        IdentifierExtraction.extract(
          text: unlabelled(ocr.text),
          blocks: <PlateBlock>[
            for (final OcrBlock block in ocr.blocks)
              (
                text: unlabelled(block.text),
                top: block.bounds.top,
                confidence: block.confidence,
              ),
          ],
          fields: identity,
        ),
      );
      for (final String key in identified.ambiguousKeys) {
        findings.add(
          'The photographed identifier for $key has no unique field. Review the evidence.',
        );
      }
      for (final IdentifierCandidate candidate in identified.candidates) {
        if (mapped.labelledKeys.contains(candidate.fieldKey)) continue;
        final TemplateField field = bundle.fields.firstWhere(
          (TemplateField field) => field.fieldKey == candidate.fieldKey,
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
            findings.add(rejection.reason);
          }
          continue;
        }
        if (OcrFieldValue.read(
              guarded.value!,
              TemplateMapper.fieldFromRow(field),
            ) ==
            null) {
          findings.add(
            'The photographed value for ${candidate.fieldKey} needs manual review.',
          );
          continue;
        }
        proposals.add(
          _proposal(
            photo: photo,
            ocr: ocr,
            fieldKey: candidate.fieldKey,
            value: guarded.value!,
            snippet: candidate.blockText,
            confidence: candidate.confidence,
            index: candidate.blockIndex,
            method: 'identifier-pattern',
          ),
        );
      }
    }
    return (proposals: proposals, findings: findings);
  }
}

ProposedValue _proposal({
  required Photo photo,
  required OcrResult ocr,
  required String fieldKey,
  required String value,
  required String snippet,
  required double confidence,
  required int? index,
  required String method,
}) => (
  fieldKey: fieldKey,
  value: value,
  confidence: confidence,
  evidence: EvidenceLinking.forValue(
    photoId: photo.id,
    regionJson: index == null ? null : StageSupport.region(ocr.blocks[index]),
    snippet: snippet,
    confidence: confidence,
  ),
  provenance: Provenance.stamp(
    source: 'ocr',
    method: method,
    provider: 'on-device',
    model: ocr.engine,
    promptVersion: 'local-2',
  ),
);
