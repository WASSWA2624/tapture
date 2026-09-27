import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/compatibility_status.dart';

void main() {
  test('statuses sort best fit first, as the target sheet lists them', () {
    final List<CompatibilityStatus> sorted =
        <CompatibilityStatus>[
          CompatibilityStatus.incompatible,
          CompatibilityStatus.compatible,
          CompatibilityStatus.compatibleWithDifferences,
        ]..sort(
          (CompatibilityStatus a, CompatibilityStatus b) =>
              a.index.compareTo(b.index),
        );
    expect(sorted, <CompatibilityStatus>[
      CompatibilityStatus.compatible,
      CompatibilityStatus.compatibleWithDifferences,
      CompatibilityStatus.incompatible,
    ]);
  });
}
