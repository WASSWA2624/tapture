import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/confidence.dart';
import 'package:tapture/features/processing/domain/evidence_linking.dart';
import 'package:tapture/features/processing/domain/proposal_application.dart';
import 'package:tapture/features/processing/domain/provenance.dart';

void main() {
  final ProvenanceStamp stamp = Provenance.stamp(
    source: 'ai',
    method: 'extract',
    provider: 'backend',
    model: 'default',
    promptVersion: 'v1',
  );

  ProposedValue proposed(String key, String? value, double confidence) {
    return (
      fieldKey: key,
      value: value,
      confidence: confidence,
      evidence: EvidenceLinking.forValue(photoId: 'photo-1'),
      provenance: stamp,
    );
  }

  test('verified and hand-entered values are skipped, with the skip kept', () {
    final ApplicationPlan plan = ProposalApplication.apply(
      proposals: <ProposedValue>[
        proposed('serial', 'SN999', 0.99),
        proposed('location', 'Store', 0.99),
        proposed('make', 'Grundfos', 0.99),
      ],
      existing: const <ExistingValue>[
        (
          fieldKey: 'serial',
          capturedValue: 'SN1',
          verified: true,
          source: 'ai',
        ),
        (
          fieldKey: 'location',
          capturedValue: 'Ward 2',
          verified: false,
          source: 'manual',
        ),
      ],
      high: 0.85,
      medium: 0.6,
      requiredKeys: const <String>[],
    );

    expect(plan.writes.map((ProposalWrite w) => w.fieldKey), <String>['make']);
    expect(plan.skips, hasLength(2));
    expect(plan.skips.first, contains('verified'));
    expect(plan.skips.last, contains('by hand'));
  });

  test('bands follow the configured thresholds', () {
    final ApplicationPlan plan = ProposalApplication.apply(
      proposals: <ProposedValue>[
        proposed('a', 'x', 0.9),
        proposed('b', 'y', 0.7),
      ],
      existing: const <ExistingValue>[],
      high: 0.95,
      medium: 0.65,
      requiredKeys: const <String>[],
    );
    expect(plan.writes.first.band, ConfidenceBand.medium);
    expect(plan.writes.last.band, ConfidenceBand.medium);
    expect(plan.status, ProposalApplication.extractedStatus);
  });

  test('a review-required value forces NEEDS_REVIEW', () {
    final ApplicationPlan plan = ProposalApplication.apply(
      proposals: <ProposedValue>[proposed('serial', 'SN1', 0.2)],
      existing: const <ExistingValue>[],
      high: 0.85,
      medium: 0.6,
      requiredKeys: const <String>[],
    );
    expect(plan.writes.single.band, ConfidenceBand.reviewRequired);
    expect(plan.needsReview, isTrue);
    expect(plan.status, ProposalApplication.needsReviewStatus);
  });

  test('a required field still empty forces NEEDS_REVIEW', () {
    final ApplicationPlan plan = ProposalApplication.apply(
      proposals: <ProposedValue>[
        proposed('make', 'Grundfos', 0.99),
        proposed('purchase_year', null, 0),
      ],
      existing: const <ExistingValue>[],
      high: 0.85,
      medium: 0.6,
      requiredKeys: const <String>['purchase_year'],
    );
    expect(
      plan.writes.map((ProposalWrite w) => w.fieldKey),
      <String>['make'],
      reason: 'a missing value is not written as a guess',
    );
    expect(plan.status, ProposalApplication.needsReviewStatus);
  });

  test('each write keeps its evidence and provenance', () {
    final ApplicationPlan plan = ProposalApplication.apply(
      proposals: <ProposedValue>[proposed('make', 'Grundfos', 0.99)],
      existing: const <ExistingValue>[],
      high: 0.85,
      medium: 0.6,
      requiredKeys: const <String>['make'],
    );
    final ProposalWrite write = plan.writes.single;
    expect(write.evidence, isNotEmpty);
    expect(write.provenance, stamp);
    expect(write.source, 'ai');
    expect(plan.status, ProposalApplication.extractedStatus);
  });
}
