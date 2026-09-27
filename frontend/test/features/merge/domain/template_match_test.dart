import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/compatibility_issue.dart';
import 'package:tapture/features/merge/domain/template_match.dart';

void main() {
  TemplateMatch match(List<CompatibilityIssue> issues) {
    return TemplateMatch(
      incomingId: 'there',
      name: 'Pump check',
      templateKey: 'pump',
      localId: 'here',
      issues: <({CompatibilityIssue issue, String field})>[
        for (final CompatibilityIssue issue in issues)
          (issue: issue, field: 'Serial'),
      ],
    );
  }

  test('a match blocks only when one of its issues does', () {
    expect(match(const <CompatibilityIssue>[]).blocks, isFalse);
    expect(
      match(const <CompatibilityIssue>[
        CompatibilityIssue.changedLabel,
        CompatibilityIssue.otherVersion,
      ]).blocks,
      isFalse,
    );
    expect(
      match(const <CompatibilityIssue>[
        CompatibilityIssue.changedLabel,
        CompatibilityIssue.typeCannotHold,
      ]).blocks,
      isTrue,
    );
  });
}
