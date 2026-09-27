import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/compatibility_issue.dart';

void main() {
  test('only a missing match, a missing filled field and a type that cannot '
      'hold the values block a merge (D15)', () {
    expect(
      <CompatibilityIssue>[
        for (final CompatibilityIssue issue in CompatibilityIssue.values)
          if (issue.blocks) issue,
      ],
      <CompatibilityIssue>[
        CompatibilityIssue.noMatch,
        CompatibilityIssue.missingField,
        CompatibilityIssue.typeCannotHold,
      ],
    );
  });

  test('every difference only warns (FE-SIMP-08)', () {
    for (final CompatibilityIssue issue in <CompatibilityIssue>[
      CompatibilityIssue.otherVersion,
      CompatibilityIssue.localOnlyFields,
      CompatibilityIssue.changedRequiredness,
      CompatibilityIssue.changedLabel,
      CompatibilityIssue.changedOptions,
      CompatibilityIssue.changedType,
      CompatibilityIssue.unfilledMissing,
    ]) {
      expect(issue.blocks, isFalse, reason: issue.name);
    }
  });
}
