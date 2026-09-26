import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/confidence.dart';

void main() {
  test('a score bands against the thresholds it is given', () {
    ConfidenceBand band(double score) {
      return Confidence.band(score: score, high: 0.85, medium: 0.6);
    }

    expect(band(0.99), ConfidenceBand.high);
    expect(band(0.85), ConfidenceBand.high, reason: 'the cut is inclusive');
    expect(band(0.84), ConfidenceBand.medium);
    expect(band(0.6), ConfidenceBand.medium);
    expect(band(0.59), ConfidenceBand.reviewRequired);
    expect(band(0), ConfidenceBand.reviewRequired);
  });

  test('a project with stricter thresholds bands the same score lower', () {
    expect(
      Confidence.band(score: 0.9, high: 0.95, medium: 0.8),
      ConfidenceBand.medium,
    );
    expect(
      Confidence.band(score: 0.9, high: 0.85, medium: 0.6),
      ConfidenceBand.high,
    );
  });
}
