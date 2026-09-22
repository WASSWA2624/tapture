import 'confidence.dart';
import 'evidence_linking.dart';
import 'provenance.dart';

/// Writes proposals. Nothing here is approved data.
///
/// A verified field and a hand-entered field are skipped and the skip is
/// recorded. A review-required value, or a required field that is still
/// empty, sets the record to needs review.
final class ProposalApplication {
  /// Status written when a person must look.
  static const String needsReviewStatus = 'needsReview';

  /// Status written when every applied value is above review.
  static const String extractedStatus = 'extracted';

  /// Decides writes, skips and the record status.
  static ApplicationPlan apply({
    required List<ProposedValue> proposals,
    required List<ExistingValue> existing,
    required double high,
    required double medium,
    required List<String> requiredKeys,
  }) {
    final Map<String, ExistingValue> current = <String, ExistingValue>{
      for (final ExistingValue value in existing) value.fieldKey: value,
    };
    final List<ProposalWrite> writes = <ProposalWrite>[];
    final List<String> skips = <String>[];
    final Set<String> filled = <String>{};
    var review = false;
    for (final ProposedValue proposal in proposals) {
      final ExistingValue? prior = current[proposal.fieldKey];
      if (prior != null && prior.verified) {
        skips.add('${proposal.fieldKey} is already verified.');
        if (prior.valueRaw != null && prior.valueRaw!.isNotEmpty) {
          filled.add(proposal.fieldKey);
        }
        continue;
      }
      if (prior != null && _manual(prior.source)) {
        skips.add('${proposal.fieldKey} was entered by hand.');
        if (prior.valueRaw != null && prior.valueRaw!.isNotEmpty) {
          filled.add(proposal.fieldKey);
        }
        continue;
      }
      if (prior != null &&
          prior.valueRaw != null &&
          prior.valueRaw!.isNotEmpty) {
        skips.add('${proposal.fieldKey} already has a captured value.');
        filled.add(proposal.fieldKey);
        continue;
      }
      if (proposal.value == null || proposal.value!.isEmpty) {
        continue;
      }
      final ConfidenceBand band = Confidence.band(
        score: proposal.confidence,
        high: high,
        medium: medium,
      );
      if (band == ConfidenceBand.reviewRequired) {
        review = true;
      }
      writes.add((
        fieldKey: proposal.fieldKey,
        proposed: proposal.value,
        confidence: proposal.confidence,
        source: proposal.provenance.source,
        band: band,
        evidence: proposal.evidence,
        provenance: proposal.provenance,
      ));
      filled.add(proposal.fieldKey);
    }
    for (final String key in requiredKeys) {
      if (!filled.contains(key)) {
        review = true;
      }
    }
    return (
      writes: writes,
      skips: skips,
      needsReview: review,
      status: review ? needsReviewStatus : extractedStatus,
    );
  }
}

/// A value already stored on the record.
typedef ExistingValue = ({
  String fieldKey,
  String? valueRaw,
  bool verified,
  String source,
});

/// A proposal that has passed the no-invention guard.
typedef ProposedValue = ({
  String fieldKey,
  String? value,
  double confidence,
  List<EvidenceDraft> evidence,
  ProvenanceStamp provenance,
});

/// One insert. The captured text is [proposed], written once by the repository.
typedef ProposalWrite = ({
  String fieldKey,
  String? proposed,
  double confidence,
  String source,
  ConfidenceBand band,
  List<EvidenceDraft> evidence,
  ProvenanceStamp provenance,
});

/// What [ProposalApplication.apply] decided.
typedef ApplicationPlan = ({
  List<ProposalWrite> writes,
  List<String> skips,
  bool needsReview,
  String status,
});

bool _manual(String source) {
  final String folded = source.toLowerCase();
  return folded == 'manual' || folded == 'typed';
}
